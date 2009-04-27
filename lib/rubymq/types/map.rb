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


class RubyMQ::Types::Map < RubyMQ::Types::Vbin32
  def self.pack data
    case data
      when RubyMQ::Types::Map
        super(data.to_rubymq_bytestream)
      when Hash
        super(new(data).to_rubymq_bytestream)
      else
        raise "Unsupported type for packing to RubyMQ::Types::Map"
    end
  end

  def self.unpack stream, lazy = false
    new(super(stream, lazy))
  end
  
  def initialize data = {}
    case data
      when RubyMQ::Stream
        @stream = data
      when Hash
        @items = data
      else
        raise "Unsupported type for initializing RubyMQ::Types::Map"
    end
  end

  def to_rubymq_bytestream
    if @items
      @items.inject(RubyMQ::Types::Uint32.pack(@items.length)) do |packed, (key, value)|
        packager = RubyMQ::Types.type?(value)
        packed += RubyMQ::Types::Str8.pack(key.to_s) + RubyMQ::Types.code?(packager) + packager.pack(value)
      end
    else
      @stream
    end
  end
  
  def dup
    lazy_unpack
    self.class.new(@items.dup)
  end
  
  def lazy_unpack
    if @stream && !@items
      @items = {}

      (RubyMQ::Types::Uint32.unpack(@stream)).times do
        @items[RubyMQ::Types::Str8.unpack(@stream).to_sym] = RubyMQ::Types.class?(@stream.get(1)).unpack(@stream, true)
      end

      remove_instance_variable(:@stream)
    end
  end
  
  def [] key
    lazy_unpack
    unpacked_key key
  end
  
  def unpacked_key key
    if @items[key].respond_to?(:rubymq_unpack)
      @items[key] = @items[key].rubymq_unpack
    else
      @items[key]
    end
  end
  
  def []= key, value
    lazy_unpack
    
    @items[key] = value
  end
  
  def has_key? key
    lazy_unpack
    @items.has_key? key
  end

  def keys
    lazy_unpack
    @items.keys
  end
  
  def delete key
    lazy_unpack
    @items.delete key
  end
  
  def only(*allowed)
    lazy_unpack
    
    result = {}
    allowed.each {|key| result[key] = unpacked_key(key)}
    return result
  end
  
  def except(*allowed)
    lazy_unpack

    result = {}
    @items.each_key {|key| result[key] = unpacked_key(key) unless allowed.include?(key)}
    return result
  end

  def merge!(hash)
    lazy_unpack
    @items.merge!(hash)
  end

  def merge(hash)
    lazy_unpack
    @items.merge(hash)
  end

  # TODO: Full-futured proxy for @items
end
