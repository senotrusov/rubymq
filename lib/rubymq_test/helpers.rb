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


def loop_with_benchmark(name, block_limit)
  count = 0
  block_count = 0
  start_time = nil

  loop do
    yield

    start_time = Time.now unless start_time
    count += 1
    
    if count == block_limit
      block_count += 1
      count = 0

      elapsed = Time.now - start_time
      total = block_count * block_limit
      puts "#{name}: #{total} in #{elapsed} at #{total / elapsed} MPS"
    end
  end
end

def spawn_threads count
  (1..count).each do |i|
    Thread.new do
      begin
        yield(i)
      rescue StandardError => exception
        puts "#{i}: #{exception.inspect_with_backtrace}"
        raise exception
      end
    end
  end
end
