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
 

module RubyMQ::EndpointApplication
  def initialize_with_endpoint(endpoint)
    @endpoint = endpoint
    @consumers = endpoint.consumers
    @producers = endpoint.producers
    @transactional = endpoint.transactional
    @logger = endpoint.logger
    self
  end
  
  attr_reader :endpoint, :consumers, :producers, :transactional, :logger
  attr_reader :client, :sequence_number, :consumer
  attr_accessor :message

  def process_message client, message, sequence_number, consumer, process_method = :process, *args
    @client = client
    @message = message
    @sequence_number = sequence_number
    @consumer = consumer

    log_before_processing(message) if @logger.debug?
    
    if @transactional && RubyMQ.initialized_orm == :activerecord
      ActiveRecord::Base.transaction {invoke_process_method(process_method, *args)}
    else
      invoke_process_method(process_method, *args)
    end
  end

  def log_before_processing message
    @logger.debug("Processing message from #{@consumer.name} " + message.inspect)
  end

  def invoke_process_method(process_method, *args)
    if self.respond_to?(call_method = "#{@consumer.name}_#{@endpoint.name}")
      __send__(call_method, *args)
      
    elsif self.respond_to?(@consumer.name)
      __send__(@consumer.name, *args)

    elsif self.respond_to?(@endpoint.name)
      __send__(@endpoint.name, *args)

    elsif self.respond_to?(process_method)
      __send__(process_method, *args)
      
    else
      raise "No process method like '#{@consumer.name}_#{@endpoint.name}', '#{@consumer.name}', '#{@endpoint.name}' or '#{process_method}' found in #{self.class}"
    end
  end

  # transmit channel, message
  # transmit channel
  # transmit message
  # transmit
 
  def transmit channel = nil, message = nil, &block
    if !message
      message = (channel.kind_of?(RubyMQ::Message::Message) || channel.kind_of?(Hash)) ? channel : @message
    end
    
    channel = case channel
      when Symbol
        @producers[channel].channel
      when String
        channel
      when RubyMQ::Application::Producer
        channel.channel
      else
        @producers[:default].channel
      end
    
    if message.kind_of?(RubyMQ::Message::Message)
      message.acquired_xact = @sequence_number
    else
      message[:acquired_xact] = @sequence_number
    end
    
    @client.message channel, message, &block
  end
end
