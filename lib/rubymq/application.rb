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
 

class RubyMQ::Application < RubyMQ::AbstractApplication
  autoload :Consumer,   'rubymq/application/consumer'
  autoload :Daemon,     'rubymq/application/daemon'
  autoload :Endpoint,   'rubymq/application/endpoint'
  autoload :Factory,    'rubymq/application/factory'
  autoload :Producer,   'rubymq/application/producer'
  autoload :Recver,     'rubymq/application/recver'
  autoload :Schedule,   'rubymq/application/schedule'
  autoload :Scheduler,  'rubymq/application/scheduler'
  autoload :SchedulingConsumer, 'rubymq/application/scheduling_consumer'
  autoload :Worker,     'rubymq/application/worker'
  
  def initialize(args)
    @endpoints_list = []
    @endpoints = {}

    @only_endpoints = args[:only_endpoints]
    
    @incoming_messages = Queue.new

    super(args)
  end

  def only_endpoints_list
    @only_endpoints ? @endpoints_list.select{|endpoint| @only_endpoints.include?(endpoint.name.to_s)} : @endpoints_list
  end
  
  def initialize_endpoint_applications
    only_endpoints_list.each do |endpoint|
      endpoint.initialize_endpoint_application
    end
  end

  attr_reader :recver, :worker, :scheduler, :client

  private
  
  def start
    @client = RubyMQ::Client.new
    
    @threads.push(@recver = RubyMQ::Application::Recver.new(self, @client, @incoming_messages))
    @threads.push(@worker = RubyMQ::Application::Worker.new(self, @client, @incoming_messages))
    @threads.push(@scheduler = RubyMQ::Application::Scheduler.new(self, @client, @daemon.scheduler_state_file))
  end
  
  def terminate_connections
    # TODO: gracefully terminate - unsubscribe, wait for workers.
    @client.close if @client
  end
  
  public

  # Define application endpoint
  # :name is optional
  def endpoint(args = {}, &block)
    new_endpoint = RubyMQ::Application::Endpoint.new(self, args, &block)
    
    @endpoints_list << new_endpoint
    @endpoints[new_endpoint.name] = new_endpoint
  end
  
  attr_reader :endpoints_list, :endpoints
end
