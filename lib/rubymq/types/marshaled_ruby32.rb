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


class RubyMQ::Types::MarshaledRuby32 < RubyMQ::Types::Lazy32
  def self.pack data
    if data.kind_of?(RubyMQ::Types::MarshaledRuby32)
      RubyMQ::Types::Lazy32.pack(data)
    else
      RubyMQ::Types::Vbin32.pack(Marshal.dump(data))
    end
  end

  def rubymq_unpack
    Marshal.restore(@stream)
  rescue ArgumentError => argument_error
    if (matchdata = argument_error.message.match(/undefined class\\\/module ([\\\w:]*\\\w)/))
      matchdata[1].constantize
      retry
    else
      raise argument_error
    end
  end
end
