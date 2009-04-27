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
 

class RubyMQ::Application::Recver
  def initialize(application, client, incoming_messages)
    @application       = application
    @logger            = application.logger
    @client            = client
    @incoming_messages = incoming_messages
    
    @thread = Thread.new_with_exception_handling(@application.logger, lambda {|exception| @application.reape! "recver_thread, #{exception.class}: #{exception.message}"}) {thread}
  end
  
  def terminate
    # Application is expected to issue a @client.close before this call, so thread will terminate by exception raised from @client.read_originations
  end
  
  def join
    @thread.join
  end
  
  private

  def thread
    loop do
      frame = @client.read_originations
#      @logger.debug("Received frame: " + frame.payload.inspect) if @logger.debug?
      send HANDLERS[frame.payload.class], frame
    end

  rescue *RubyMQ::TCPTransport::SOCKET_EXEPTIONS => exception
    @application.reape! "recver_thread, #{exception.class}: #{exception.message}"
  ensure
    post_thread_action
  end
  
  def post_thread_action
    @incoming_messages.push nil
  end
  
  HANDLERS = Hash.new do |hash, key|
    raise "Unsupported protocol originating #{key}, server is expected to only originates #{hash.keys.inspect}"
  end
  
  HANDLERS.merge!(
    RubyMQ::Message::Message => :handle_message
  )
  
  def handle_message frame
    @incoming_messages.push frame
  end
end
