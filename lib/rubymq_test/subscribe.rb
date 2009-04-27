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

begin
  session = RubyMQ::SimpleSession.new

  subscribe_resp = session.send_command RubyMQ::Channel::Subscribe.new(
    :channel => "foo_channel",
    :subscription_key => nil,
    :mode => 0x00,
    :must_process_in => 15,
    :tear_attachment => false,
    :condition => RubyMQ::Condition::None.new
  )

  puts "subscribe_resp: #{subscribe_resp.inspect}"

  loop do
    message, sequence_number = session.recv

    puts "#{sequence_number} -- #{message.body[:text]} -- #{message.inspect}\n\n"

    STDOUT.write "Hit enter to reply: "
    STDIN.gets.strip

    session.send_response RubyMQ::Message::MessageResponse.new(:result => 0x00, :action => 0x00), sequence_number
  end

rescue Interrupt
end