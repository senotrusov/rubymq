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


require 'uuid'

class RubyMQ::UUID < String
  def self.config args
#    UUID::STATE_FILE[0..-1] = args[:state_file]
#    UUID.setup unless File.exist?(args[:state_file])
#    UUID.config(args)
  end
  
  def self.new(uuid = nil)
    uuid ||= UUID.generate(:compact)
    
    super(
      if uuid.length == 16
        uuid
      elsif uuid.length == 32 || (uuid = uuid.delete("-")).length == 32
        [uuid[0,8].hex, uuid[8,8].hex, uuid[16,8].hex, uuid[24,8].hex].pack("NNNN")
      else
        raise "Incorrect UUID given"
      end
    )
  end
  
  def inspect
    "\"#{self.to_s}\""
  end
  
  def to_s
    text = sprintf('%08x%08x%08x%08x', *(unpack("NNNN")))
    "#{text[0,8]}-#{text[8,4]}-#{text[12,4]}-#{text[16,4]}-#{text[20,12]}"
  end
end
