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
 

class RubyMQ::Application::Endpoint
  def initialize(application, args)
    @application = application
    @logger = @application.logger
    @endpoint_application = args.delete :application
    
    @args = args
    @name = args.delete(:name) || RubyMQ::UUID.new.to_s
    @transactional = args.delete(:transactional) == false ? false : true
    
    @consumers_list = []
    @consumers = Hash.new do |hash, key|
      raise "Unknown consumer #{key}, endpoint is only have consumers: #{hash.keys.inspect}"
    end
    
    @producers_list = []
    @producers = Hash.new do |hash, key|
      raise "Unknown producer #{key}, endpoint is only have producers: #{hash.keys.inspect}"
    end
    
    @schedules_list = []
    @schedules = {}
    
    yield(self) if block_given?
  end
  
  def initialize_endpoint_application
    @endpoint_application.initialize_with_endpoint(self) if @endpoint_application.respond_to?(:initialize_with_endpoint)
  end
  
  def [] key
    @args[key]
  end
  
  attr_reader :application, :logger, :name, :transactional
  
  attr_reader :consumers_list, :consumers
  attr_reader :producers_list, :producers
  attr_reader :schedules_list, :schedules
  
  def consumer(channel, args = {})
    new_consumer = RubyMQ::Application::Consumer.new(self, channel, args)
    
    @consumers_list << new_consumer
    @consumers[new_consumer.name] = new_consumer

    @consumers[:default] = new_consumer if args[:default] || !@consumers.has_key?(:default)
  end

  def consume_to_public_methods_from channel_prefix, args = {}
    endpoint_application_class = @endpoint_application.kind_of?(Class) ? @endpoint_application : @endpoint_application.class

    public_methods = endpoint_application_class.instance_methods

    while ((endpoint_application_class = endpoint_application_class.superclass) != Object)
    end

    public_methods -= endpoint_application_class.instance_methods

    public_methods.each do |public_method|
      consumer(channel_prefix + public_method, args)
    end
  end

  def producer(channel, args = {})
    new_producer = RubyMQ::Application::Producer.new(channel, args)
    
    @producers_list << new_producer
    @producers[new_producer.name] = new_producer
    
    @producers[:default] = new_producer if args[:default] || !@producers.has_key?(:default)
  end

  def schedule(name, args = {})
    new_schedule = RubyMQ::Application::SchedulingConsumer.new(@application, self, args.merge(:name => name))
    
    @schedules_list << new_schedule
    @schedules[new_schedule.id] = new_schedule if new_schedule.id
  end
  
  def process_message message, sequence_number, consumer
    if @endpoint_application.kind_of?(Class)
      processor = @endpoint_application.new
      processor.initialize_with_endpoint self
      processor.process_message @application.client, message, sequence_number, consumer
      
    elsif @endpoint_application.class < RubyMQ::EndpointApplication
      @endpoint_application.process_message @application.client, message, sequence_number, consumer
    else
      raise "Unsupported :application type. Must be a class or instance of the class with the RubyMQ::EndpointApplication mixed in"
    end
  end
end
