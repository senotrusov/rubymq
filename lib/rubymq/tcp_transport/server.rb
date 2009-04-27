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


class RubyMQ::TCPTransport::Server
  include RubyMQ::TCPTransport

  def initialize config
    super config
    
    @socket = TCPServer.new(@address, @port)
  end
  
  def accept
    loop do
      yield(RubyMQ::TCPTransport::AcceptedClient.new(@socket.accept, @timeout, @timeout_callback))
    end
  rescue IOError
  end
end
