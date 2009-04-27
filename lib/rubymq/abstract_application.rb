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


class RubyMQ::AbstractApplication
  autoload :Daemon,     'rubymq/abstract_application/daemon'

  def initialize(args)
    @name   = args[:name] || raise(":name must be specified")
    @reaper = args[:reaper]
    @logger = args[:logger]
    @daemon = args[:daemon]
    @threads = []
  end
  
  attr_reader :name, :logger
  attr_accessor :reaped
  
  def reape! reason
    @reaper.push self, reason
  end
  
  def terminate
    raise("Must be called only by ThreadReaper") unless caller.first =~ /thread_reaper/
    
    begin
      terminate_connections
    rescue IOError
    end

    @threads.each {|thread| thread.terminate}
  end
  
  def join
    @threads.each {|thread| thread.join}
  end
  
  def start_with_reaper_rescue
    start
  rescue *RubyMQ::TCPTransport::SOCKET_EXEPTIONS => exception
    reape! "start, #{exception.class}: #{exception.message}"
  end
end
