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


class RubyMQ::Server::Daemon
  def initialize config = {}
    @transport_config = config[:transport] || RubyMQ::DEFAULT_TRANSPORT
  end

  def name
    "rubymq_server.#{@transport_config[:port]}"
  end

  def define_options(options)
    options.header << "RubyMQ -- Ruby's message queueing server"
    options.option "--sqlite-dir DIRECTORY", "Directory to hold sqlite database. Default to 'log', fallbacks to '.', may be absolute"
    options.option "--transport-address ADDRESS", "Transport address. Default to '127.0.0.1'"
    options.option "--require FILE...", "Require one or more ruby files. Usefull for detailed debug logging without 'ERROR UNPACKING VALUE' screening"
  end

  attr_reader :sqlite_dir, :uuid_state_file
  
  def apply_options(options)
    @sqlite_dir = options["sqlite-dir"] || 'log'
    @sqlite_dir = '.' unless File.directory?(@sqlite_dir)
    
    @transport_config[:address] = options["transport-address"] if options["transport-address"]

    if options["require"]
      options["require"].each do |file|
        require file
      end
    end
  end

  def start
    RubyMQ::UUID.config(:logger => RubyMQ.logger, :state_file => @uuid_state_file)
    
    RubyMQ.logger.info "Starting server transport #{@transport_config.inspect}"

    @server_socket = @transport_config[:type]::Server.new @transport_config
    @switcher = RubyMQ::Server::Switcher.new(self)
    @client_pool = RubyMQ::Server::ClientPool.new(@switcher)

    @server_socket.accept do |client|
      @client_pool.new(client)
    end

    @client_pool.terminate
    @client_pool.join
    
    @switcher.terminate
    @switcher.join
  end
  
  # Note кое где при аварийной остановке треда вызывается эта функция.
  def stop
    # If I call @server_socket.close inside termination_signal, then IOError "stream closed" was not raised in server socket acceptor
    # I am not sure how different ruby interpreters will behave on this.
    # Also, I am not sure why doing the same thing in stopper_thread does not raise IOError "stream closed" too.
    Thread.new_with_exception_handling(RubyMQ.logger, lambda { Process.exit!(2) }) do
      Thread.pass
      
      until @server_socket
        sleep 0.01
      end
      
      begin
        @server_socket.close
      rescue IOError
      end
    end
  end
end
