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
 

class RubyMQ::Application::Worker
  def initialize(application, client, incoming_messages)
    @application       = application
    @logger            = @application.logger
    @client            = client
    @incoming_messages = incoming_messages
    
    @subscriptions_mutex = Mutex.new
    
    @subscriptions = Hash.new do |hash, key|
      raise "Unknown subscription key #{key.inspect}, client is only subscriber of #{hash.keys.inspect}"
    end
    
    @application.only_endpoints_list.each do |endpoint|
      endpoint.consumers_list.each {|consumer| subscribe consumer}
      endpoint.schedules_list.each {|schedule| subscribe schedule}
    end

    @thread = Thread.new_with_exception_handling(@application.logger, lambda {|exception| @application.reape! "worker_thread, #{exception.class}: #{exception.message}"}) {thread}
  end
  
  def subscribe consumer
    @subscriptions_mutex.synchronize do
      @subscriptions[@client.subscribe(consumer.channel)] = consumer
    end
  end
  
  def terminate
    # TODO @incoming_messages.push nil
  end
  
  def join
    @thread.join
  end
  
  private

  def thread
    while(frame = @incoming_messages.shift)
      
      begin
        @subscriptions_mutex.synchronize {@subscriptions[frame.payload.subscription_key]}.process_message frame.payload, frame.sequence_number
        @client.response_with_message_processed frame
      rescue StandardError => exception
        begin
          @client.response_with_message_processing_failure frame
        rescue *RubyMQ::TCPTransport::SOCKET_EXEPTIONS => nested_exception
          @application.reape! "worker_thread#response_with_message_processing_failure, #{nested_exception.class}: #{nested_exception.message}"
        end

        @logger.error("#{@application.name} processing message #{frame.payload.inspect}\n#{exception.inspect_with_backtrace}")
      end
      
    end
  end
end
