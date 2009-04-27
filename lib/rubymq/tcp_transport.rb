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


require 'rubymq_facets/core/tcp_socket'

module RubyMQ::TCPTransport
  SOCKET_EXEPTIONS = [
    IOTimeoutError,
    IOError,
    EOFError,
    Errno::EBADF,
    Errno::ECONNRESET,
    Errno::ECONNREFUSED,
    Errno::EPIPE,
    Errno::ETIMEDOUT,
    Errno::EHOSTUNREACH,
    Errno::ESHUTDOWN,
    Errno::ENETDOWN,
    Errno::ENETUNREACH,
    Errno::ENETRESET,
    Errno::EIO,
    Errno::EHOSTDOWN,
    Errno::ECONNABORTED]
  
  # At least Windows XP does not have it
  SOCKET_EXEPTIONS.push(Errno::EPROTO) if defined?(Errno::EPROTO)
  SOCKET_EXEPTIONS.push(Errno::ECOMM)  if defined?(Errno::ECOMM)

  autoload :AcceptedClient,  'rubymq/tcp_transport/accepted_client'
  autoload :Client,          'rubymq/tcp_transport/client'
  autoload :Server,          'rubymq/tcp_transport/server'
  autoload :Transmiting,     'rubymq/tcp_transport/transmiting'
  
  def initialize config
    @address          = config[:address]
    @port             = config[:port]
    @timeout          = config[:timeout]
    @timeout_callback = config[:timeout_callback]
  end
  
  attr_reader :timeout
  
  def port
    @port
  end

  def close
    @socket.close
  end
end
