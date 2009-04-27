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


class RubyMQ::Server::Switcher
  def initialize(daemon)
    @daemon = daemon
    
    @redelivery_limit = 20
    @redelivery_delay_power = 2
    @redelivery_delay_base_seconds = 60

    # Not sure -- is a Hash.new thread-safe -- so use mutex
    @channel_autocreation_mutex = Mutex.new
    
    @channels = Hash.new do |hash, key|
      @channel_autocreation_mutex.synchronize do
        if hash.has_key?(key)
          hash[key]
        else
          hash[key] = PrioritizedQueue.new
        end
      end
    end
    
    @transit_watcher = RubyMQ::Server::TransitWatcher.new(@daemon, self)
    @scheduler = RubyMQ::Server::Scheduler.new(@daemon, self)

    @storage = RubyMQ::Storage::Sqlite.new("#{@daemon.sqlite_dir}/#{@daemon.name}.messages.db")

    RubyMQ.logger.info "Loading messages from persistent storage..."
    
    @storage.load.each do |persistent_id, channel, message|
      message.persistent_id = persistent_id
      deliver_message message, false
    end

    RubyMQ.logger.info "Done loading messages from persistent storage"
  end
  
  # TODO: on aborting a transaction messaging system may became inconsistent, so we need to shut down server (or only switcher?) and reload all from storage
  def transaction(&block)
    @storage.transaction(&block)
  end
  
  def deliver_message message, persistent
    if persistent
      if message.persistent_id
        @storage.update(message.channel, message, message.persistent_id)
      else
        message.persistent_id = @storage.insert(message.channel, message)
      end
    end
      
    if message.header[:scheduled]
      @scheduler.push message
    elsif message.header[:priority]
      @channels[message.channel].priority_push message
    else
      @channels[message.channel].push message
    end
  end
  
  def message_response(message, response)
    @transit_watcher.delivered message
    
    if response.action == 0x01 # drop
      @storage.delete(message.persistent_id) if message.persistent_id
      
    elsif response.action == 0x02 # redeliver
      message.redelivered = true
      message.redelivery_count = message.redelivery_count ? message.redelivery_count + 1 : 1
      message.header[:scheduled] = Time.now + response.redelivery_delay

      deliver_message message, true
      
    elsif response.action == 0x03 # invalid
      message.channel = "/invalid_messages"

      deliver_message message, true
    end
  end
  
  def message_processing_timeout message
    message.redelivered = true
    message.redelivery_count = message.redelivery_count ? message.redelivery_count + 1 : 1
    
    if message.redelivery_count >= @redelivery_limit
      message.channel = "/invalid_messages" 
    else
      message.header[:scheduled] = Time.now + @redelivery_delay_base_seconds * (message.redelivery_count ** @redelivery_delay_power)
    end
    deliver_message message, true
  end
  
  def configure channel, config
    
  end
  
  def send_directly_to_channel_subscribers channel, message
    @channels[channel].push message
  end
  
  def fetch_message subscription
    message = @channels[subscription.channel].shift
    @transit_watcher.watch subscription, message if message
    return message
  end

  def terminate
    @transit_watcher.terminate
  end

  def join
    @transit_watcher.join
  end
end
