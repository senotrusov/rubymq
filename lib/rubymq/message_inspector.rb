#
# derived from rubyonrails.org

 
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


# Copyright (c) 2004-2007 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 

class RubyMQ::MessageInspector
  @row_even = true
  
  def self.inspect message
    result = ""

    header_color = "4;31;1"

    result << "\e[#{header_color}mchannel:\e[0m #{message.channel.inspect}, \e[#{header_color}msubscription_key:\e[0m #{message.subscription_key.inspect}, \e[#{header_color}mredelivered:\e[0m #{message.redelivered.inspect}, \e[#{header_color}mredelivery_count:\e[0m #{message.redelivery_count.inspect}, \e[#{header_color}macquired_xact:\e[0m #{message.acquired_xact.inspect}, \e[#{header_color}msimple_xact:\e[0m #{message.simple_xact.inspect}\n"
    
    message.header.keys.each do |key|
      if @row_even
        @row_even = false
        message_color, dump_color = "4;32;1", "0;1"
      else
        @row_even = true
        message_color, dump_color = "4;33;1", "0"
      end

      result << "  **** \e[#{message_color}m:#{key}\e[0m \e[#{dump_color}m#{message.header[key].inspect rescue "ERROR UNPACKING VALUE"}\e[0m\n"
    end

    message.body.keys.each do |key|
      if @row_even
        @row_even = false
        message_color, dump_color = "4;32;1", "0;1"
      else
        @row_even = true
        message_color, dump_color = "4;33;1", "0"
      end

      result << "  \e[#{message_color}m:#{key}\e[0m \e[#{dump_color}m#{message.body[key].inspect rescue "ERROR UNPACKING VALUE"}\e[0m\n"
    end
    
    return result
  end
end
