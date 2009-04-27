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


module RubyMQ::Session
  class Connect
    include RubyMQ::Packager
  
    packing_and_accessor :application, :str8
    packing_and_accessor :password, :str8
    packing_and_accessor :session, :uuid
    
    packed_attribute_filling_initializer
  end
  
  class ConnectResponse
    include RubyMQ::Packager
  
    packing_and_accessor :result, :uint8
    packing_and_accessor :session, :uuid
    
    packed_attribute_filling_initializer
  end

  
  class Disconnect
    include RubyMQ::Packager
  end

  class DisconnectResponse
    include RubyMQ::Packager
  end

  
  class Configure
    include RubyMQ::Packager
  
    packing_and_accessor :prefetch, :uint16
    packing_and_accessor :persistance, :uint32
    
    packed_attribute_filling_initializer
  end
  
  class ConfigureResponse
    include RubyMQ::Packager
  
    packing_and_accessor :result, :uint8
    
    packed_attribute_filling_initializer
  end

  class Ping
    include RubyMQ::Packager
  end

  class PingResponse
    include RubyMQ::Packager
  end

  RubyMQ::Packager.register 0x01, self,
    0x01 => Connect,
    0x02 => ConnectResponse,
    0x03 => Disconnect,
    0x04 => DisconnectResponse,
    0x05 => Configure,
    0x06 => ConfigureResponse,
    0x07 => Ping,
    0x08 => PingResponse
end
