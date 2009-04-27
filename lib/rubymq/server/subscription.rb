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


class RubyMQ::Server::Subscription
  attr_reader :must_process_in
  attr_reader :session
  attr_reader :channel
  
  def initialize subscribe, switcher, session, messenger
    @subscription_key = subscribe.subscription_key
    @must_process_in = subscribe.must_process_in
    
    @switcher = switcher
    @session = session
    @messenger = messenger
    
    @channel = subscribe.channel
    
    @must_terminate = false
    
    @subscription_thread = Thread.new_with_exception_handling(RubyMQ.logger, lambda {|exception| @session.push_to_reaper "subscription, #{exception.class}"}) {subscription_thread}
  end
  
  def terminate
    @must_terminate = true

    begin
      @switcher.send_directly_to_channel_subscribers @channel, nil
    end until @subscription_thread.join(0.01)
  end
  
  def join
    @subscription_thread.join
  end

  private

  def subscription_thread
    loop do
      break if @must_terminate
      # TODO: sleep here as flow control solution
      if (message = @switcher.fetch_message(self))
        message.subscription_key = @subscription_key
        @messenger.deliver_message message
      end
    end
  end
  
end
