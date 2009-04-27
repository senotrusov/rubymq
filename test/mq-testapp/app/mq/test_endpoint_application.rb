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
 

class TestEndpointApplication
  include RubyMQ::EndpointApplication
  
  def periodic
    transmit :body => {:text => "HELLO!"}
  end
    
  def print
    puts message.body[:text]
    
    message.body[:user] = User.find_by_login(message.body[:text])

    message.body[:text] = message.body[:text] + " " + message.body[:text]
    
    transmit message
  end
  
  def post_print
    puts message.body[:text]

    if message.body[:user] && message.body[:email]
      message.body[:user].email = message.body[:email]
      puts "SAVING!"
      message.body[:user].save
    end
  end
  
  
  def process
    puts "PROCESSING #{message.inspect} -- #{message.body.inspect}"
    transmit message
  end
end
