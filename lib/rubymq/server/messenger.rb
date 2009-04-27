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


# Оптимальное значение prefetch связано со скоростью обработки сообщения.
# При очень большой скорости prefetch не влияет совсем
# 
# При скорости в 10 ms под VMware:
# 
#     1 - 60 MPS
#     2 - 87 MPS
#     3 - 90 MPS
#     5 - 90 MPS
#    10 - 90 MPS
#    50 - 90 MPS
#   100 - 90 MPS
#     
# При отсутствии задержки в обработке (очень нестабильные цифры)
#     1 - 120 MPS
#     3 - 210 MPS
#     5 - 204 MPS
#
# Только subscriber и server на одной VMWare машине - 400 MPS

class RubyMQ::Server::Messenger
  def initialize session, switcher
    @session = session
    @switcher = switcher
    @prefetch_limit = 3

    @sended_mutex = Mutex.new
    @sended = {}
    @message_delivered = ConditionVariable.new
    
    @must_terminate = false
    @subscriptions = {}
    @subscriptions_mutex = Mutex.new
  end
  
  def create_subscription subscribe
    @subscriptions_mutex.synchronize do
      unless @must_terminate
        subscribe.subscription_key ||= RubyMQ::UUID.new

        @subscriptions[subscribe.subscription_key] = RubyMQ::Server::Subscription.new(subscribe, @switcher, @session, self)
        result = 0x00
      else
        result = 0x04
        subscribe.subscription_key = nil
      end
      
      RubyMQ::Channel::SubscribeResponse.new(
        :result => result,
        :condition_failure_details => 0x00,
        :subscription_key => subscribe.subscription_key)
    end
  end

  def terminate
    @subscriptions_mutex.synchronize do
      @must_terminate = true

      @sended_mutex.synchronize do
        @message_delivered.broadcast
      end
      
      @subscriptions.each {|key, subscription| subscription.terminate}
    end
  end
  
  def join
    @subscriptions_mutex.synchronize do
      @subscriptions.each {|key, subscription| subscription.join}
    end
  end
  
  def deliver_message message
    return if @must_terminate
    
    @sended_mutex.synchronize do
      if @sended.length >= @prefetch_limit
        @message_delivered.wait_while(@sended_mutex) {@sended.length >= @prefetch_limit && !@must_terminate}
      end
      
      sequence_number = @session.send_to_client message
      @sended[sequence_number] = message
    end
  end
  
  def message_response response, sequence_number
    @sended_mutex.synchronize do
      @switcher.message_response(@sended.delete(sequence_number), response)
      @message_delivered.signal
    end
  end
end
