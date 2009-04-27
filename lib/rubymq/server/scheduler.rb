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
 

class RubyMQ::Server::Scheduler
  def initialize daemon, switcher
    @daemon   = daemon
    @switcher = switcher

    @queue = []
    @mutex = Mutex.new
    @queue_checked = false

    @thread = Thread.new_with_exception_handling(RubyMQ.logger, lambda { @daemon.stop }) {thread}
  end
  
  def push message
    @mutex.synchronize do
      if @queue.empty? || @queue.last.header[:scheduled] <= message.header[:scheduled]
        @queue.push message
      else
        @queue[@queue.each_with_index {|item, index| break index if item.header[:scheduled] > message.header[:scheduled]},0] = message
      end
      @queue_checked = false
    end
    @thread.run until @queue_checked
  end
  
  def thread
    loop do
      sleep_interval = nil
      
      @mutex.synchronize do
        @queue_checked = true
        
        now = Time.now
        loop do
          if @queue.empty?
            sleep_interval = nil
            break
            
          elsif @queue.first.header[:scheduled] <= now
            message = @queue.shift
            message.header.delete :scheduled
            
            # NOTE: There are no transaction here since this operation is not persistent. It's ok to reschedule message on failure
            @switcher.deliver_message message, false
          else
            sleep_interval = @queue.first.header[:scheduled] - now
            break
          end
        end
      end
      
      sleep_interval ? sleep(sleep_interval) : sleep
    end
  end
end