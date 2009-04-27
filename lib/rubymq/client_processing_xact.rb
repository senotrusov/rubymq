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
 

class RubyMQ::ClientProcessingXact
  def initialize client, sequence_number
    @client = client
    @sequence_number = sequence_number
  end
  
  def message channel, message = {}, &block
    if message.kind_of?(RubyMQ::Message::Message)
      message.acquired_xact = @sequence_number
    else
      message[:acquired_xact] = @sequence_number
    end
    
    @client.message channel, message, &block
  end
end
