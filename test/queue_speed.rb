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
require 'thread'
#require 'fastthread'
require 'benchmark'

Benchmark.bmbm do |x|
  x.report do 
    i = 0
    q = Queue.new
    p = Thread.new {100_000.times{q.push(i+= 1)}; q.push nil}
    c = Thread.new {while(v=q.shift); puts v; end}
    p.join
    c.join
  end
end
