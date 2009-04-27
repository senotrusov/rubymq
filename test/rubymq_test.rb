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


require 'test/unit'
require 'vendor/plugins/rubymq_3/test/packaging_test'

class RubyMQTest < Test::Unit::TestCase
  def inspect variable
    variable.inspect.gsub(/0x\w{8}/, '')
  end
  
  def test_packing
    c = RubyMQ::Session::Configure.new
    
    c.prefetch = 10
    c.persistance = 36000
    assert_equal "01 05 00 0A 00 00 8C A0",
      c.to_rubymq_bytestream.to_hex_view

    assert_equal "00 00 00 08 01 05 00 0A 00 00 8C A0",
      (packed = RubyMQ::Types::Struct32.pack(c)).to_hex_view
    
    c_unpacked = RubyMQ::Types::Struct32.unpack(RubyMQ::Stream.new(packed))
    
    assert_equal inspect(c), inspect(c_unpacked)

    pt = RubyMQ::PackagingTest.new

    pt.boolean_true = true
    pt.boolean_false = false
    pt.uint8 = 100
    pt.uint16 = 300
    pt.uint32 = 100000
    pt.uint64 = 4294967295000
    pt.vbin8 = "aa"
    pt.vbin16 = "bb"
    pt.vbin32 = "cc"
    pt.str8 = "dd"
    pt.str16 = "ee"
    pt.str32 = "ff"

    pt.struct32 = c
    pt.datetime = Time.at(1210055546)
    pt.uuid = RubyMQ::UUID.new("55f514f0fd64012a85be000c299e3e39")
    pt.sequence_no = 200000
    pt.marshaled_ruby32 = {:k => :v}

    assert_equal "00 00 00 63 FF F0 01 00 64 01 2C 00 01 86 A0 00 00 03 E7 FF FF FC 18 02 61 61 00 02 62 62 00 00 00 02 63 63 02 64 64 00 02 65 65 00 00 00 02 66 66 00 00 00 08 01 05 00 0A 00 00 8C A0 00 00 00 00 48 1F FB 7A 55 F5 14 F0 FD 64 01 2A 85 BE 00 0C 29 9E 3E 39 00 03 0D 40 00 00 00 0A 04 08 7B 06 3A 06 6B 3A 06 76",
      (packed = RubyMQ::Types::Struct32.pack(pt)).to_hex_view

    assert_equal 103, packed.length
    
    pt_unpacked = RubyMQ::Types::Struct32.unpack(RubyMQ::Stream.new(packed))
    
    assert_equal inspect(pt), inspect(pt_unpacked)
  end
  
  # affect map unpacking
  def test_call_order
    @call_order = []
    
    h = {}
    h[record_call_order(:first)] = record_call_order(:second)
   
    assert_equal [:first, :second], @call_order
  end
  
  def record_call_order value
    @call_order << value
    return  value
  end
  
  def test_type_guessing
    assert_equal RubyMQ::Types::Void, RubyMQ::Types.type?(nil)
    
    assert_equal RubyMQ::Types::Boolean, RubyMQ::Types.type?(true)
    assert_equal RubyMQ::Types::Boolean, RubyMQ::Types.type?(false)

    assert_equal RubyMQ::Types::Uint8, RubyMQ::Types.type?(1)
    assert_equal RubyMQ::Types::Uint16, RubyMQ::Types.type?(11231)
    assert_equal RubyMQ::Types::Uint32, RubyMQ::Types.type?(11231231)
    assert_equal RubyMQ::Types::Uint64, RubyMQ::Types.type?(1123123123123)
    assert_equal RubyMQ::Types::MarshaledRuby32, RubyMQ::Types.type?(184467440737095516150)
    assert_equal RubyMQ::Types::MarshaledRuby32, RubyMQ::Types.type?(-1)
    assert_equal RubyMQ::Types::MarshaledRuby32, RubyMQ::Types.type?(1.2)
    
    assert_equal RubyMQ::Types::Vbin8, RubyMQ::Types.type?(RubyMQ::Stream.new("123"))
    assert_equal RubyMQ::Types::Vbin16, RubyMQ::Types.type?(RubyMQ::Stream.new("123" * 200))
    assert_equal RubyMQ::Types::Vbin32, RubyMQ::Types.type?(RubyMQ::Stream.new("123" * 655350))
    
    assert_equal RubyMQ::Types::Uuid, RubyMQ::Types.type?(RubyMQ::UUID.new)
    
    assert_equal RubyMQ::Types::Str8, RubyMQ::Types.type?("123")
    assert_equal RubyMQ::Types::Str16, RubyMQ::Types.type?("123" * 200)
    assert_equal RubyMQ::Types::Str32, RubyMQ::Types.type?("123" * 655350)
    # TODO One day we will make test for string > uint32 long
    # assert_equal RubyMQ::Types::MarshaledRuby32, 

    assert_equal RubyMQ::Types::Datetime, RubyMQ::Types.type?(Time.now)
    
    assert_equal RubyMQ::Types::Map, RubyMQ::Types.type?({})
    assert_equal RubyMQ::Types::Map, RubyMQ::Types.type?(RubyMQ::Types::Map.new({}))
    
    assert_equal RubyMQ::Types::MarshaledRuby32, RubyMQ::Types.type?([])
    assert_equal RubyMQ::Types::Struct32, RubyMQ::Types.type?(RubyMQ::Session::Configure.new)
  end
  
  def test_map
    map = RubyMQ::Types::Map.new
    
    map[:void] = nil
    map[:boolean] = true
    map[:array] = [1,2,3]

    c = RubyMQ::Session::Configure.new
    c.prefetch = 10
    c.persistance = 36000

    map[:struct] = c

    # Order of hash is unpredictable, so this may broke sometime, but when it brokes we need to examine - is it realy order of hash or some other issue occured.
    assert_equal "00 00 00 3D 00 00 00 04 05 61 72 72 61 79 E2 00 00 00 0A 04 08 5B 08 69 06 69 07 69 08 07 62 6F 6F 6C 65 61 6E 08 01 04 76 6F 69 64 F0 06 73 74 72 75 63 74 AB 00 00 00 08 01 05 00 0A 00 00 8C A0",
      (map_packed = RubyMQ::Types::Map.pack(map)).to_hex_view
 
    assert_equal 65, map_packed.length
      
    map_unpacked = RubyMQ::Types::Map.unpack(RubyMQ::Stream.new(map_packed))
    
    assert_equal nil, map_unpacked[:void]
    assert_equal true, map_unpacked[:boolean]
    assert_equal [1,2,3], map_unpacked[:array]
    assert_equal 10, map_unpacked[:struct].prefetch
    assert_equal 36000, map_unpacked[:struct].persistance
    
    map_lazy_packed_unpacked = RubyMQ::Types::Map.unpack(
      RubyMQ::Stream.new(
        RubyMQ::Types::Map.pack(
          RubyMQ::Types::Map.unpack(
            RubyMQ::Stream.new(map_packed)
          )
        )
      )
    )

    assert_equal nil, map_lazy_packed_unpacked[:void]
    assert_equal true, map_lazy_packed_unpacked[:boolean]
    assert_equal [1,2,3], map_lazy_packed_unpacked[:array]
    assert_equal 10, map_lazy_packed_unpacked[:struct].prefetch
    assert_equal 36000, map_lazy_packed_unpacked[:struct].persistance
  end
  
#  def test_queue_bug
#    #require 'rubygems'
#    #require 'thread'
#    #require 'fastthread'    
#
#    q = Queue.new
#
#    thread = Thread.new {q.shift}
#    thread.terminate
#
#    q.push 1    
#  end
end
