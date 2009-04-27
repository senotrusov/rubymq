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


class RubyMQ::PackagingTest
  include RubyMQ::Packager
  
  packing_and_accessor :boolean_true, :boolean
  packing_and_accessor :boolean_false, :boolean
  packing_and_accessor :uint8, :uint8
  packing_and_accessor :uint16, :uint16
  packing_and_accessor :uint32, :uint32
  packing_and_accessor :uint64, :uint64
  packing_and_accessor :vbin8, :vbin8
  packing_and_accessor :vbin16, :vbin16
  packing_and_accessor :vbin32, :vbin32
  packing_and_accessor :str8, :str8
  packing_and_accessor :str16, :str16
  packing_and_accessor :str32, :str32

  packing_and_accessor :struct32, :struct32
  packing_and_accessor :datetime, :datetime
  packing_and_accessor :uuid, :uuid
  packing_and_accessor :sequence_no, :sequence_no
  packing_and_accessor :marshaled_ruby32, :marshaled_ruby32
end

RubyMQ::Packager.register 0xff, RubyMQ::PackagingTest,
  0xf0 => RubyMQ::PackagingTest
