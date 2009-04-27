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


class RubyMQ::Server::ClientPool
  def initialize switcher
    @switcher = switcher
    
    @clients = []
    @clients_mutex = Mutex.new
    @must_terminate = false
    @reaper_queue = Queue.new
    @reaper_thread = Thread.new_with_exception_handling(RubyMQ.logger, lambda { Process.exit!(3) }) {reaper_thread}
  end
  
  def new transport
    @clients_mutex.synchronize do
      unless @must_terminate
        @clients.push RubyMQ::Server::ClientSession.new(transport, self, @switcher)
      else
        transport.close
      end
    end
  end
  
  def push_to_reaper client
    @reaper_queue.push client
  end
  
  def terminate
    @clients_mutex.synchronize do
      @must_terminate = true
      @clients.each {|client| client.push_to_reaper "Closing client pool" }
    end
    
    @reaper_queue.push nil
  end
  
  def join
    @reaper_thread.join
  end

  private

  def reaper_thread
    while (client = @reaper_queue.shift)
      client.terminate
      client.join
      @clients_mutex.synchronize { @clients.delete client }
      RubyMQ.logger.debug "#{client.inspect} reaped"
    end
  end
end
