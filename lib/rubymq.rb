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


require 'rubymq_facets'
require 'rubymq_facets/core_ext'
require 'rubymq_facets/externals/greedy_loader'

module RubyMQ
  class ApplicationConfigError    < StandardError; end
  class ApplicationBehaviourError < StandardError; end
  class ClassNotFound             < NameError; end
  class CantServeMessage          < StandardError; end
  class MessageActiveTillExpired  < StandardError; end
  class TransmissionError         < StandardError; end
  class NotImplemented            < StandardError; end
  
  class << self
    attr_accessor :logger, :environment
    
    def emergency_logger
      require 'rubymq_facets/externals/logger' unless defined?(Merb::Logger)
      @emergency_logger ||= Merb::Logger.new(STDOUT, :debug, " ~ ", true)
    end
    
    attr_accessor :initialized_orm
    
    def initialize_orm(orm_name)
      return if self.initialized_orm
      
      case orm_name
      when :activerecord
        
        require 'activerecord'
        require 'rubymq_facets/active_record'
        require 'yaml'
        require 'erb'
        
        ActiveRecord::Base.logger = RubyMQ.logger || RubyMQ.emergency_logger
        ActiveRecord::Base.colorize_logging = false
        
        ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read('config/database.yml')).result)
        ActiveRecord::Base.establish_connection RubyMQ.environment

        require 'rubymq_facets/thread'
        
        Thread.new_with_exception_handling(RubyMQ.logger || RubyMQ.emergency_logger, lambda { Process.exit!(50) }) do
          Thread.current.priority = -5
          loop do
            sleep 15 * 60
            ActiveRecord::Base.verify_active_connections!
          end
        end

      else
        raise "Unsupported ORM #{orm_name}"
      end
      
      self.initialized_orm = orm_name
    end
    
    attr_accessor :applications
    RubyMQ.applications = {}
    
    def application(args, &block)
      args[:name] ||= (args[:class] && args[:class].to_s.snake_case)
      
      raise(":name or :class must be specified") unless args[:name]
      
      app_factory = (@applications[args[:name]] ||= RubyMQ::Application::Factory.new)
      app_factory.push_args args
      app_factory.push_configuration block
    end
  end
  
  autoload :UUID,          'rubymq/uuid'
  autoload :Stream,        'rubymq/stream'
  autoload :Types,         'rubymq/types'
  autoload :Packager,      'rubymq/packager'
  autoload :IncomingFrame, 'rubymq/incoming_frame'
  autoload :OutgoingFrame, 'rubymq/outgoing_frame'
  
  autoload :Session,   'rubymq/session'
  autoload :Channel,   'rubymq/channel'
  autoload :Condition, 'rubymq/condition'
  autoload :Message,   'rubymq/message'
  
  autoload :MessageInspector, 'rubymq/message_inspector'
  
  RubyMQ::Session
  RubyMQ::Channel
  RubyMQ::Condition
  RubyMQ::Message
  
  autoload :Client,               'rubymq/client'
  autoload :ClientProcessingXact, 'rubymq/client_processing_xact'
  
  autoload :Server,        'rubymq/server'
  autoload :Storage,       'rubymq/storage'
  
  autoload :TCPTransport,  'rubymq/tcp_transport'
  
  autoload :Application,           'rubymq/application'
  autoload :AbstractApplication,   'rubymq/abstract_application'
  autoload :EndpointApplication,   'rubymq/endpoint_application'

  # TODO: 3-5 seconds timeout for webserver client
  # TODO: Under virtualisation timer ticks may be irregular. Timeout error may occur if time sync quickly jump to future.
  DEFAULT_TRANSPORT = {:type => RubyMQ::TCPTransport, :address => "127.0.0.1", :port => 44555, :timeout => 60 * 30}
end
