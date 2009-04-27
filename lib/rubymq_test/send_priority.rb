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


require 'rubygems'
require 'rubymq'

$session = RubyMQ::SimpleSession.new

def snd text, priority
  response = $session.send_command RubyMQ::Message::Message.new(:channel => "foo_channel", :header => (priority ? {:priority => true} : {}), :body => {:text => text})
  puts "response: #{response.inspect}"
end

snd "normal 1", false
snd "normal 2", false
snd "normal 3", false
snd "normal 4", false
snd "normal 5", false
snd "PRIORITY 1", true
snd "PRIORITY 2", true
snd "PRIORITY 3", true
snd "PRIORITY 4", true
snd "PRIORITY 5", true
