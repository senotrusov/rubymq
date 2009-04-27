$KCODE = "UTF8"

require 'rubygems'
require 'rubymq'

mq = RubyMQ::Client.new

STDOUT.write "Enter user login: "
text = STDIN.gets.strip

STDOUT.write "Enter new email: "
email = STDIN.gets.strip
  
mq.message "/test/print", :body => {:text => text, :email => email}
