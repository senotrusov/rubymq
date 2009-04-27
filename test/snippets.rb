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


def bench times
  start = Time.now
  times.times {yield}
  puts (Time.now - start).inspect
end

require 'benchmark'

def bm times
  Benchmark.bm do |x|
    x.report { times.times {yield} }
  end
  nil
end

def bmbm times
  Benchmark.bmbm do |x|
    x.report { times.times {yield} }
  end
  nil
end

s = RubyMQ::Storage::Sqlite.new('db/rubymq.db'); nil
s.load
bench(10_000) {s.insert "foo", {:x=>:y}}

s.load

script/runner vendor/plugins/rubymq_3/test/rubymq_test.rb


script/runner -e development_daemon "DaemonRunner.new(RubyMQ::Server::Daemon.new).run"




session = RubyMQ::SimpleSession.new
session.send RubyMQ::Message::Message.new(:channel => "foo_channel", :header => {}, :body => {:text => "Hello, world!"})




(cd ~/gems_development/rubymq/; rake installq); rubymq_server run

test_rubymq subscribe_with_benchmark
test_rubymq send_with_benchmark