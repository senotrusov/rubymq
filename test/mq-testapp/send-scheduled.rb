$KCODE = "UTF8"

require 'rubygems'
require 'rubymq'

mq = RubyMQ::Client.new

STDOUT.write "Enter message text: "
text = STDIN.gets.strip
  
mq.message "/test/print", :body => {:text => text}, :header => {:scheduled => Time.now + 10}
