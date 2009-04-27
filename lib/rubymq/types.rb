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


module RubyMQ::Types
  autoload :Generic,    'rubymq/types/generic'
  autoload :Boolean,    'rubymq/types/boolean'
  autoload :Uint8,      'rubymq/types/uint8'
  autoload :Uint16,     'rubymq/types/uint16'
  autoload :Uint32,     'rubymq/types/uint32'
  autoload :Uint64,     'rubymq/types/uint64'
  autoload :Vbin8,      'rubymq/types/vbin8'
  autoload :Vbin16,     'rubymq/types/vbin16'
  autoload :Vbin32,     'rubymq/types/vbin32'
  autoload :Str8,       'rubymq/types/str8'
  autoload :Str16,      'rubymq/types/str16'
  autoload :Str32,      'rubymq/types/str32'
  autoload :Void,       'rubymq/types/void'
  autoload :Lazy32,     'rubymq/types/lazy32'
#  autoload :Array,      'rubymq/types/array'
  autoload :Map,        'rubymq/types/map'
  autoload :Struct32,   'rubymq/types/struct32'
  autoload :Datetime,   'rubymq/types/datetime'
  autoload :Uuid,       'rubymq/types/uuid'
  autoload :SequenceNo, 'rubymq/types/sequence_no'
  autoload :MarshaledRuby32, 'rubymq/types/marshaled_ruby32'

  def self.register class_codes
    @class_codes ||= {}
    @classes ||= {}
    
    class_codes.each do |klass, code|
      raise "Class #{klass.inspect} can not be registred twice" if @classes[klass]
      
      next unless code
      
      packed_code = RubyMQ::Types::Uint8.pack(code)
      
      @class_codes[packed_code] = klass
      @classes[klass] = packed_code
    end
  end
  
  def self.code? klass
    @classes[klass] || raise("Unable to find code for class #{klass.inspect}")
  end
  
  def self.class? packed_code
    @class_codes[packed_code] || raise("Unable to find class for code #{packed_code.inspect}")
  end
  
  def self.type? data
    if data.class < RubyMQ::Packager
      Struct32
    else
      case data
      when RubyMQ::Types::Map, Hash
        Map
        
      when RubyMQ::Types::MarshaledRuby32
        MarshaledRuby32

      when NilClass
        Void

      when TrueClass, FalseClass
        Boolean

      when RubyMQ::UUID
        Uuid

      when RubyMQ::Stream
        if (length = data.length) <= 255
          Vbin8
        elsif length <= 65535
          Vbin16
        elsif length < 4294967295
          Vbin32
        else
          MarshaledRuby32
        end

      when String
        if (length = data.length) <= 255
          Str8
        elsif length <= 65535
          Str16
        elsif length < 4294967295
          Str32
        else
          MarshaledRuby32
        end

      when Time
        Datetime

      when Integer
        if data >= 0
          if data <= 255
            Uint8
          elsif data <= 65535
            Uint16
          elsif data < 4294967295
            Uint32
          elsif data < 18446744073709551615
            Uint64
          else
            MarshaledRuby32
          end
        else
          MarshaledRuby32
        end

      else
          MarshaledRuby32
      end
    end
  end

  register(
    Boolean => 0x08,
    Uint8 => 0x02,
    Uint16 => 0x12,
    Uint32 => 0x22,
    Uint64 => 0x32,
    Vbin8 => 0x80,
    Vbin16 => 0x90,
    Vbin32 => 0xa0,
    Str8 => 0x85,
    Str16 => 0x95,
    Str32 => 0xe0,
    Void => 0xf0,
    #Array => 0xaa,
    Map => 0xa8,
    Struct32 => 0xab,
    Datetime => 0x38,
    Uuid => 0x48,
    SequenceNo => nil, 
    MarshaledRuby32 => 0xe2
  )
end
