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


ENV["RAILS_ENV"] = "test"

require File.dirname(__FILE__) + '/../../../../config/environment'

require 'test_help'

class ThreadLockTest < Test::Unit::TestCase
  
  def test_locking
    result = ThreadsafeArray.new
    lock = ThreadLock.new
    threads = []
    
    threads << shared(result, lock, "01") 
    threads << shared(result, lock, "02")
    threads << shared(result, lock, "03")

    threads << exclusive(result, lock, "04") 

    threads << shared(result, lock, "05") 
    threads << shared(result, lock, "06")
    threads << shared(result, lock, "07")
    
    threads << exclusive(result, lock, "08") 
    threads << exclusive(result, lock, "09") 
    threads << exclusive(result, lock, "10") 
    threads << exclusive(result, lock, "11") 
    threads << exclusive(result, lock, "12") 
    threads << exclusive(result, lock, "13") 
    threads << exclusive(result, lock, "14") 
    threads << exclusive(result, lock, "15") 
    threads << exclusive(result, lock, "16") 

    threads << shared(result, lock, "17") 
    threads << shared(result, lock, "18")
    threads << shared(result, lock, "19")
    threads << shared(result, lock, "20") 
    threads << shared(result, lock, "21")
    threads << shared(result, lock, "22")
    threads << shared(result, lock, "23") 
    threads << shared(result, lock, "24")
    threads << shared(result, lock, "25")

    threads.each do |thread|
      thread.join
    end
    
    puts result.join("\n")
  end

  def shared result, lock, id 
    Thread.new {lock.shared{result.push "#{Time.now}: SHARED #{id} BEGIN"; sleep 0; result.push "#{Time.now}: SHARED #{id} END";}}
  end
  
  def exclusive result, lock, id
    Thread.new {lock.exclusive{result.push "#{Time.now}: EXCLUSIVE #{id} BEGIN"; sleep 0; result.push "#{Time.now}: EXCLUSIVE #{id} END";}}
  end
  
  def test_nesting
    lock = ThreadLock.new

    assert_equal "HELLO", lock.shared{"HELLO"}

    assert_raises(NestingThreadLockError) do
      lock.exclusive{lock.exclusive{"HELLO"}}
    end

    assert_raises(NestingThreadLockError) do
      lock.exclusive{lock.exclusive{"HELLO"}}
    end

    assert_raises(NestingThreadLockError) do
      lock.shared{lock.exclusive{"HELLO"}}
    end
  
    assert_equal "HELLO", lock.exclusive{lock.shared{"HELLO"}}
    assert_equal "HELLO", lock.shared{lock.shared{lock.shared{"HELLO"}}}
  end
end
