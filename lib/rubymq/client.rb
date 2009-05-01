# 
#  Copyright 2007-2008 Stanislav Senotrusov <senotrusov@gmail.com>
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
 

require 'rubymq-facets/core/thread'

class RubyMQ::Client
  def initialize config = {}
    @sequence_number = 0
    @transport_config = config[:transport] || RubyMQ::DEFAULT_TRANSPORT
    
    @redelivery_limit = config[:redelivery_limit] || 20
    @redelivery_delay_power = config[:redelivery_delay_power] || 2
    @redelivery_delay_base_seconds = config[:redelivery_delay_base_seconds] || 60

      # Долгое ожидание входящего сообщения порождает исходящее.
      # Для применения такого подхода мы должны быть уверены, что исходящий трафик генерируется после (ответ) или перед (запрос)
      # каждым входящим сообщением, таким образом, не бывает ситуаций, когда идёт входящий трафик, но нет исходящего.
    @transport = @transport_config[:type]::Client.new(@transport_config.merge(:timeout => (@transport_config[:timeout] * 0.9).to_i, :timeout_callback => lambda {write RubyMQ::Session::Ping.new}))

    @writer_mutex = Mutex.new
    
    @reader_mutex = Mutex.new
    @passive_reader_mutex = Mutex.new
    @frame_arrived = ConditionVariable.new
    @received = []
  end

  def write payload, response_to = nil
    
    @writer_mutex.synchronize do
      @transport.send RubyMQ::OutgoingFrame.new((@sequence_number += 1), response_to, payload)
      @sequence_number
    end
    
  rescue *RubyMQ::TCPTransport::SOCKET_EXEPTIONS => exception
    begin
      @transport.close
    rescue IOError
    end
    raise exception
  end
  
  def write_and_read_response payload
    read_response_to(write(payload))
  end
  
  def read_originations
    read_response_to 0
  end
  
  # TODO: Подразумевается, что ответ обязательно придёт, то есть сервер никогда не сможет забыть ответить.
  # В случае exception на своей стороне, сервер закрывает сессию, однако, теоретически, он может забыть ответить.
  # Я пока не смог придумать хорошую реализацию, которая бы отслеживала слишком долгое ожидание.
  # Ожидать запроса с response_to == nil можно действительно долго, нас же интересуют ожидания с
  # ненулевым response_to - ответы, которые должны приходить быстро.
  # 
  # Одно из решений - реализовать watchdog thread (который можно прервать в любое время, т.е. он бы не требовал join),
  # который бы, по аналогии с transit_watcher, засыпал бы, и, просыпаясь, смотрел - нет осталось ли старых знакомых.
  
  def read_response_to response_to
    loop do
      if @reader_mutex.try_lock
        
        @passive_reader_mutex.synchronize do
          if(frame = check_received(response_to))
            @reader_mutex.unlock
            @frame_arrived.broadcast
            return frame
          end
        end
        
        loop do
          begin
            frame = read
          rescue *RubyMQ::TCPTransport::SOCKET_EXEPTIONS => exception
            @passive_reader_mutex.synchronize do
              @reader_mutex.unlock
              @frame_arrived.broadcast
            end
            raise(exception)
          end
          
          @passive_reader_mutex.synchronize do
            if frame.response_to == response_to
              @reader_mutex.unlock
              @frame_arrived.broadcast
              return frame
            else
              @received.push frame
              @frame_arrived.broadcast
            end
          end
          
        end
        
      else
        
        @passive_reader_mutex.synchronize do
          if(frame = check_received response_to)
            return frame
          end
          @frame_arrived.wait(@passive_reader_mutex)
        end
        
      end
    end
  end

  def read
    while(RubyMQ::Session::Ping === (frame = @transport.recv).payload)
      write RubyMQ::Session::PingResponse.new, frame.sequence_number
    end
    return frame
  rescue *RubyMQ::TCPTransport::SOCKET_EXEPTIONS => exception
    begin
      @transport.close
    rescue IOError
    end
    raise exception
  end
  
  def close
    begin
      @transport.close
    rescue IOError
    end
  end
  
  class Error < StandardError; end
  class SubscribeError < Error; end
  class MessageError < Error; end
  
  def subscribe channel, attrs = {}
    attrs = {   
      :channel => channel,
      :subscription_key => nil,
      :mode => :push,
      :must_process_in => 60,
      :tear_attachment => false,
      :condition => RubyMQ::Condition::None.new }.merge attrs
    
    attrs[:mode] = RubyMQ::Channel::Subscribe::MODE_IDS[attrs[:mode]]
    
    response_frame = write_and_read_response RubyMQ::Channel::Subscribe.new(attrs)
    
    if response_frame.payload.result == 0x00
      return response_frame.payload.subscription_key
    else
      raise(SubscribeError, "#{RubyMQ::Channel::SubscribeResponse::RESULTS[response_frame.payload.result]}")
    end
  end
  
  def message channel, message = {}
    unless message.kind_of?(RubyMQ::Message::Message)
      message[:header]  ||= {}
      message[:body]    ||= {}
      
      message = RubyMQ::Message::Message.new(message)
    end

    message.channel = channel
    message.header[:message_id] = RubyMQ::UUID.new unless message.header.has_key?(:message_id)
    
    yield(message = message.dup) if block_given?
    
    response_frame = write_and_read_response message

    if response_frame.payload.result == 0x00
      return true
    else
      raise(MessageError, "#{RubyMQ::Message::MessageResponse::RESULTS[response_frame.payload.result]} #{message.inspect}")
    end
  end
  
  def processing_xact frame
    RubyMQ::ClientProcessingXact.new(self, frame.sequence_number)
  end
  
  def consume_message
    frame = read_originations
    
    raise "Unsupported protocol originating #{frame.payload.class}, server is expected to only originate RubyMQ::Message::Message" unless frame.payload.class == RubyMQ::Message::Message

    begin
      yield frame.payload, processing_xact(frame)
      response_with_message_processed frame
    rescue StandardError => exception
      response_with_message_processing_failure(frame) if frame
      raise exception
    end
    
  end
  
  def response_with_message_processed frame
    write RubyMQ::Message::MessageResponse.new(:result => 0x80, :action => 0x01), frame.sequence_number
  end
  
  def response_with_message_processing_failure frame, invalid = false
    redelivery_count = frame.payload.redelivery_count
    
    response = if invalid || (redelivery_count && redelivery_count >= @redelivery_limit)
        RubyMQ::Message::MessageResponse.new(:result => 0x81, :action => 0x03)
      else
        redelivery_delay = @redelivery_delay_base_seconds * ((redelivery_count ? redelivery_count + 1 : 1) ** @redelivery_delay_power)
        RubyMQ::Message::MessageResponse.new(:result => 0x81, :action => 0x02, :redelivery_delay => (redelivery_delay > 65535 ? 65535 : redelivery_delay))
      end
    
    write response, frame.sequence_number
    
    return RubyMQ::Message::MessageResponse::ACTIONS[response.action]
  end

  private
  
  def check_received response_to
    for frame in @received
      if frame.response_to == response_to
        @received.delete(frame)
        return frame
      end
    end
    return false
  end
end
