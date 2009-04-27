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


class RubyMQ::Types::Lazy32 < RubyMQ::Types::Vbin32
  def self.pack data
    super(data.to_rubymq_bytestream)
  end

  def self.unpack stream, lazy = false
    lazy_object = new(super(stream, lazy))
    
    lazy ? lazy_object : lazy_object.rubymq_unpack
  end
  
  def initialize stream
    @stream = stream
  end
  
  def to_rubymq_bytestream
    @stream
  end
end