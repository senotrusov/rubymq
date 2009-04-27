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


class RubyMQ::IncomingFrame
  INITIAL_OCTETS = 12

  attr_reader :sequence_number, :response_to, :payload_length, :payload

  def initialize initial_octets
    @sequence_number, @response_to, @payload_length = initial_octets.unpack("NNN")
    @payload_stream = RubyMQ::Stream.new(initial_octets[8,4])
  end
  
  def payload= payload
    @payload_stream << payload
    @payload = RubyMQ::Types::Struct32.unpack(@payload_stream)
  end
end
