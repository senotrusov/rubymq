# 
#  Copyright 2006-2008 Stanislav Senotrusov <senotrusov@gmail.com>
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


require 'rubymq-facets/more/threadsafe_sequence'

class RubyMQ::Server::ClientSession
  
  def initialize transport, pool, switcher
    @session_uuid = RubyMQ::UUID.new
    
    RubyMQ.logger.debug "#{self.inspect} connected #{transport.inspect} "
    
    @last_ping_activity = Time.now
    
    @transport = transport
    @pool      = pool
    @switcher  = switcher
    
    @sequence_number = ThreadsafeSequence.new(0..0xffffffff)
    
    @sender_queue = Queue.new
    
    @pushed_to_reaper = false
    @push_to_reaper_mutex = Mutex.new
    
    @must_terminate = false
    
    @subscriptions = {}
    
    @acquired_xacts = {}
    
    @messenger = RubyMQ::Server::Messenger.new(self, @switcher)

    @recver_thread = Thread.new_with_exception_handling(RubyMQ.logger, lambda {|exception| push_to_reaper "recver_thread, #{exception.class}"}) {recver_thread}
    @sender_thread = Thread.new_with_exception_handling(RubyMQ.logger, lambda {|exception| push_to_reaper "sender_thread, #{exception.class}"}) {sender_thread}
    @pinger_thread = Thread.new_with_exception_handling(RubyMQ.logger, lambda {|exception| push_to_reaper "pinger_thread, #{exception.class}"}) {pinger_thread}
  end

  def send_to_client payload, response_to = nil
    @sender_queue.push RubyMQ::OutgoingFrame.new((sequence_number = @sequence_number.nextval), response_to, payload)
    sequence_number
  end
  
  def inspect
    "ClientSession #{@session_uuid.inspect}"
  end
  
  private
  
  HANDLERS = {
    RubyMQ::Session::Ping => :handle_ping,
    RubyMQ::Session::PingResponse => :handle_ping_response,
    RubyMQ::Channel::Subscribe => :handle_channel_subscribe,
    RubyMQ::Channel::Poll => :handle_channel_poll,
    RubyMQ::Message::Message => :handle_message,
    RubyMQ::Message::MessageResponse => :handle_message_response
  }
  
  def handle_ping ping_response, sequence_number, response_to
    @last_ping_activity = Time.now
    send_to_client RubyMQ::Session::PingResponse.new, sequence_number
  end

  def handle_ping_response ping_response, sequence_number, response_to
    @last_ping_activity = Time.now
  end
  
  def handle_channel_subscribe subscribe, sequence_number, response_to
    send_to_client @messenger.create_subscription(subscribe), sequence_number
  end
  
  def handle_channel_poll poll, sequence_number, response_to
    # TODO
  end

  def handle_message message, sequence_number, response_to
    # TODO: handle acquired_xact and simple_xact
    
    acquired_xact = message.acquired_xact
    
    message.subscription_key = nil
    message.redelivered = nil
    message.redelivery_count = nil
    message.acquired_xact = nil
    message.simple_xact = nil

    if acquired_xact
      @acquired_xacts[acquired_xact] ||= []
      @acquired_xacts[acquired_xact] << message
    else
      @switcher.transaction do
        @switcher.deliver_message(message, true)
      end
    end
    send_to_client RubyMQ::Message::MessageResponse.new(:result => 0x00, :action => 0x00), sequence_number
  end
  
  def handle_message_response response, sequence_number, response_to
    @switcher.transaction do
      if (xact = @acquired_xacts.delete(response_to)) && response.result == 0x80
        xact.each do |message|
          @switcher.deliver_message(message, true)
        end
      end
      @messenger.message_response response, response_to
    end
  end
  
  def recver_thread
    loop do
      frame = @transport.recv
      
      # TODO: logging via block
      RubyMQ.logger.debug "#{self.inspect} RECV #{frame.sequence_number} (#{frame.response_to}) -- #{frame.payload.inspect}"
      
      send(HANDLERS[frame.payload.class], frame.payload, frame.sequence_number, frame.response_to)
    end
  rescue *RubyMQ::TCPTransport::SOCKET_EXEPTIONS => exception
    push_to_reaper "recver_thread, #{exception.class}"
  end
  
  def sender_thread
    loop do
      @transport.send @sender_queue.shift
    end
  rescue *RubyMQ::TCPTransport::SOCKET_EXEPTIONS => exception
    push_to_reaper "sender_thread, #{exception.class}"
  end
  
  def pinger_thread
    interval = @transport.timeout / 2
    
    sleep interval
    
    loop do
      send_to_client RubyMQ::Session::Ping.new
      
      sleep interval
      break if @must_terminate
      
      push_to_reaper("pinger_thread, Ping timeout") if @last_ping_activity < Time.now - @transport.timeout
    end
  end
  
  public
  
  def push_to_reaper reason
    @push_to_reaper_mutex.synchronize do
      unless @pushed_to_reaper
        @pushed_to_reaper = true

        RubyMQ.logger.debug "#{self.inspect} pushed to reaper (#{reason})"

        @pool.push_to_reaper(self)
      end
    end
  end
  
  # TODO terminate call must be restricted to only reaper. Until that, we must carefully not to call terminate directly.
  def terminate
    @messenger.terminate

    # terminating @pinger_thread
    @must_terminate = true

    # terminating @recver_thread
    begin
      @transport.close
    rescue IOError
    end

    # terminating @sender_thread -- it will stop sender_thread since @transport is already closed
    send_to_client RubyMQ::Session::Ping.new
  end
  
  def join
    @messenger.join
    @pinger_thread.run_and_join
    @recver_thread.join
    @sender_thread.join
  end
  
end
