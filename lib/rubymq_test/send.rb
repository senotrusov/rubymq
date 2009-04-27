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


mq = RubyMQ::Client.new

text = "Test text"
loop do
  STDOUT.write "Enter message text (or just hit enter): "
  text = STDIN.gets.strip.empty? ? text : STDIN.gets.strip
  
  mq.message "/test/incoming", :body => {:text => text}, :header => {:scheduled => Time.now + 10}
end
