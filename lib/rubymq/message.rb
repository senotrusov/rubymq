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


module RubyMQ::Message
  class Message
    include RubyMQ::Packager
  
    packing_and_accessor :channel, :str16
    packing_and_accessor :subscription_key, :uuid
    packing_and_accessor :redelivered, :boolean
    packing_and_accessor :redelivery_count, :uint8
    packing_and_accessor :acquired_xact, :sequence_no
    packing_and_accessor :simple_xact, :sequence_no
    packing_and_accessor :header, :map
    packing_and_accessor :body, :map
    
    packed_attribute_filling_initializer
    
    attr_accessor :persistent_id
    
    def [] key
      body[key]
    end

    def []= key, value
      body[key] = value
    end

    def delete(key)
      body.delete(key)
    end

    def keys
      body.keys
    end
    
    def only(*allowed)
      body.only(*allowed)
    end

    def except(*allowed)
      body.except(*allowed)
    end

    def merge!(hash)
      body.merge!(hash)
    end

    def merge(hash)
      body.merge(hash)
    end

    def inspect
      RubyMQ::MessageInspector.inspect self
    end
    
    def dup
      self.class.new(
        :channel => channel,
        :subscription_key => subscription_key,
        :redelivered => redelivered,
        :redelivery_count => redelivery_count,
        :acquired_xact => acquired_xact,
        :simple_xact => simple_xact,
        :header => header.dup,
        :body => body.dup
      )
    end
  end
  
  class MessageResponse
    include RubyMQ::Packager
  
    packing_and_accessor :result, :uint8
    packing_and_accessor :action, :uint8
    packing_and_accessor :redelivery_delay, :uint16
    
    packed_attribute_filling_initializer
    
    RESULTS = {
      0x00 => :accepted_for_delivery,
      0x01 => :bad_channel_name,
      0x02 => :authorization_failure_for_channel,
      0x03 => :unable_to_deliver_reliably,
      0x04 => :unknown_acquired_xact,
      0x05 => :unknown_simple_xact,
      0x80 => :processed,
      0x81 => :processing_failure
    }
    RESULT_IDS = RESULTS.invert
    
    ACTIONS = {
      0x00 => :no_action_required,
      0x01 => :drop,
      0x02 => :redeliver,
      0x03 => :invalid
    }
    ACTION_IDS = ACTIONS.invert
  end

  
  class Drop
    include RubyMQ::Packager
    
    packing_and_accessor :channel, :str16
    packing_and_accessor :subscription_key, :uuid
    packing_and_accessor :message_id, :uuid
    
    packed_attribute_filling_initializer
  end

  class DropResponse
    include RubyMQ::Packager

    packing_and_accessor :result, :uint8
    
    packed_attribute_filling_initializer
  end

  RubyMQ::Packager.register 0x04, self,
    0x01 => Message,
    0x02 => MessageResponse,
    0x03 => Drop,
    0x04 => DropResponse
end
