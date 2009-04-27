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


module RubyMQ::Packager
  def self.register module_code, mmodule, class_codes
    @class_codes ||= {}
    @classes ||= {}
    
    class_codes.each do |code, klass|
      raise "Class #{klass.inspect} can not be registred twice" if @classes[klass]
      
      full_code = RubyMQ::Types::Uint16.pack((module_code * 0x100) + code)
      
      @class_codes[full_code] = klass
      @classes[klass] = full_code
    end
  end
  
  def self.code? klass
    @classes[klass] || raise("Unable to find code for class #{klass.inspect}")
  end
  
  def self.class? full_code
    @class_codes[full_code] || raise("Unable to find class for code #{full_code.inspect}")
  end
  
  def initialize stream = nil
    if stream
      raise("kind_of?(RubyMQ::Stream) must be provided, instead of #{stream.inspect}") unless stream.kind_of?(RubyMQ::Stream)
      pack_sequence.each do |variable, packager|
        instance_variable_set(variable, packager.unpack(stream))
      end

      raise("Unpacking #{self.class} found extra data at the end of stream '#{stream.remains}'") unless stream.eos?
    end
  end
  
  def to_rubymq_bytestream
    pack_sequence.inject(RubyMQ::Packager.code?(self.class)) do |packed, (variable, packager)|
      packed += packager.pack(instance_variable_get(variable))
    end
  end
  
  def self.included target
    target.extend RubyMQ::PackagerClassMethods
    target.class_inheritable_accessor :pack_sequence
    target.pack_sequence = []
  end
end

module RubyMQ::PackagerClassMethods
  def packing variable, datatype
    self.pack_sequence << ["@#{variable}".to_sym, RubyMQ::Types.full_const_get("#{datatype.to_s.camel_case}")]
  end
  
  def packing_and_accessor variable, datatype
    attr_accessor variable
    packing variable, datatype
  end
  
  def packed_attribute_filling_initializer
    code = {:line => (__LINE__+1), :file => __FILE__, :code => <<-EOS
        def initialize attrs = {}
          if attrs.kind_of?(Hash)
            attrs.each do |key, value|
              instance_variable_set("@\#{key}", value)
            end
          else
            super attrs
          end
        end
      EOS
    }
    
    class_eval code[:code],
               code[:file],
               code[:line]
  end
end
