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


class RubyMQ::Types::Uint8 < RubyMQ::Types::Generic
  def self.pack data
    data = 0 unless data # TODO: implement packing flags and get rid of this
    raise(RangeError, "#{data.inspect} must fit uint8 (0-255)") if data < 0 || data > 255
    [data].pack("C")
  end
  
  def self.unpack stream, lazy = false
    stream.get(1).unpack("C").first
  end
end
