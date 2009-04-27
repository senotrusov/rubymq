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
 

class RubyMQ::Application::Daemon < RubyMQ::AbstractApplication::Daemon
  def initialize factory, options
    @factory = factory
    @options = options
    super()
  end
  
  def name
    @options["only-endpoints"] ? "#{@factory.name}_#{@options["only-endpoints"].join("_")}".to_sym : @factory.name
  end
  
  def define_options(options)
    super(options)
    options.option "--scheduler-state-file FILE", "Scheduler state file. Default to 'log/\#{name}.scheduler.state', fallbacks to './\#{name}.scheduler.state', may be absolute path"
  end

  attr_reader :scheduler_state_file

  def apply_options(options)
    super(options)
    @scheduler_state_file = options["scheduler-state-file"] || "log/#{name}.scheduler.state"
    @scheduler_state_file = "./#{name}.scheduler.state" unless File.directory?(File.dirname(@scheduler_state_file))
  end

  def start
    RubyMQ.initialize_orm :activerecord
    GreedyLoader.run
    
    super
  end

  private
  
  def produce_application
    @factory.produce(:reaper => @reaper, :logger => RubyMQ.logger, :daemon => self, :only_endpoints => @options["only-endpoints"])
  end
end
