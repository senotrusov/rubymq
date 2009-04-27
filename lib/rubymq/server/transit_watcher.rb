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


# Поверхностные наблюдения - в один момент времени в транзите могут находиться порядка 15 сообщений,
# для системы 4 consumer, 4 producer, 179MPS 0.1ms process delay
# причём при двукратном росте consumer/producer транзитная очередь не увеличивается.

class RubyMQ::Server::TransitWatcher
  SLEEP_INTERVAL = 10
  
  def initialize(daemon, switcher)
    @daemon = daemon
    @switcher = switcher
    
    @transit_mutex = Mutex.new
    @transit = {}
    
    @must_terminate = false
    @transit_watcher_thread = Thread.new_with_exception_handling(RubyMQ.logger, lambda { @daemon.stop }) {transit_watcher_thread}
  end
  
  def watch subscription, message
    @transit_mutex.synchronize do
      @transit[message] = subscription
    end
  end
  
  def delivered message
    @transit_mutex.synchronize do
      @transit.delete message
    end
  end
  
  def terminate
    @must_terminate = true
  end
    
  def join
    @transit_watcher_thread.run_and_join
  end
  
  private

  # TODO: Refactor to be more nicely.
  def transit_watcher_thread
    until @must_terminate
      redeliver = {}

      @transit_mutex.synchronize do
        @transit.each do |message, subscription|
          if subscription.kind_of?(RubyMQ::Server::Subscription)
            @transit[message] = {:subscription => subscription, :ttl => subscription.must_process_in}
            
          elsif (subscription[:ttl] -= SLEEP_INTERVAL) <= 0
            @transit.delete(message)
            redeliver[message] = subscription[:subscription]
          end
        end
      end
      
      redeliver.each do |message, subscription|
        subscription.session.push_to_reaper("must_process_in timeout")
        subscription.session.join
        @switcher.transaction do
          @switcher.message_processing_timeout message
        end
      end
      
      sleep SLEEP_INTERVAL
    end
  end

end
