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
 

class RubyMQ::Application::Consumer
  def initialize(endpoint, channel, args = {})
    @endpoint = endpoint
    @channel = channel
    @name = args[:name] || File.basename(channel).to_sym
    @args = args
    raise "Consumer name MUST be a symbol" unless @name.kind_of?(Symbol)
  end
  
  attr_reader :endpoint, :channel, :name
  
  def [] key
    @args[key]
  end
  
  def process_message message, sequence_number
    @endpoint.process_message message, sequence_number, self
  end
end
