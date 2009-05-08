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

  def self.included mq_app
    mq_app.extend RubyMQ::EndpointApplicationClassMethods

    mq_app.class_inheritable_array :before_filters
    mq_app.class_inheritable_array :after_filters

    mq_app.before_filters = []
    mq_app.after_filters = []
  end

  def process_message client, message, sequence_number, consumer, process_method = :process, *args
    @client = client
    @message = message
    @sequence_number = sequence_number
    @consumer = consumer

    log_before_processing(message) if @logger.debug?
    
    if @transactional && RubyMQ.initialized_orm == :activerecord
      ActiveRecord::Base.transaction {dispatch_process_method(process_method, *args)}
    else
      dispatch_process_method(process_method, *args)
    end
  end

  def log_before_processing message
    @logger.debug("Processing message from #{@consumer.name} " + message.inspect)
  end

  def dispatch_process_method(process_method, *args)
    if self.respond_to?(call_method = "#{@consumer.name}_#{@endpoint.name}")
      invoke_process_method(call_method, *args)
      
    elsif self.respond_to?(@consumer.name)
      invoke_process_method(@consumer.name, *args)

    elsif self.respond_to?(@endpoint.name)
      invoke_process_method(@endpoint.name, *args)

    elsif self.respond_to?(process_method)
      invoke_process_method(process_method, *args)
      
    else
      raise "No process method like '#{@consumer.name}_#{@endpoint.name}', '#{@consumer.name}', '#{@endpoint.name}' or '#{process_method}' found in #{self.class}"
    end
  end

  def invoke_process_method(process_method, *args)
    if apply_before_filters(process_method) != :stop
      __send__(process_method, *args)
      apply_after_filters process_method
    end
  end

  def apply_before_filters process_method
    apply_filters(before_filters, process_method)
  end

  def apply_after_filters process_method
    apply_filters(after_filters, process_method)
  end

  def apply_filters filters, process_method
    filters.each do |filter|
      if filter.suitable?(process_method)
        if filter.call_method
          return :stop if __send__(filter.call_method) == :stop
        end
      end
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
