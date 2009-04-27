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
require 'rubymq_facets/more/thread_reaper'

class RubyMQ::AbstractApplication::Daemon
  def initialize
    @must_terminate = false
    @mutex = Mutex.new
  end
  
  def define_options(options)
    options.option "--uuid-state-file FILE", "UUID state file. Default to 'log/uuid.state', fallbacks to './uuid.state', may be absolute path"
  end

  attr_reader :uuid_state_file

  def apply_options(options)
    @uuid_state_file = options["uuid-state-file"] || 'log/uuid.state'
    @uuid_state_file = './uuid.state' unless File.directory?(File.dirname(@uuid_state_file))
  end

  def start
    RubyMQ::UUID.config(:logger => RubyMQ.logger, :state_file => @uuid_state_file)
    
    @mutex.synchronize do
      return if @must_terminate
      @reaper = ThreadReaper.new(RubyMQ.logger)
    end
    
    loop do
      @mutex.synchronize do
        return if @must_terminate
        RubyMQ.logger.info "Starting #{name}"
        @application = produce_application
        @application.start_with_reaper_rescue
      end

      @application.join
      sleep 10 unless @must_terminate
    end
    
    @reaper.join
  end

  def stopper_thread
    @mutex.synchronize do
      @must_terminate = true
      @application.reape!("normal exit") if @application
      @reaper.terminate if @reaper
    end
  end
end
