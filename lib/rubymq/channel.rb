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


module RubyMQ::Channel
  class Subscribe
    include RubyMQ::Packager
  
    packing_and_accessor :channel, :str16
    packing_and_accessor :subscription_key, :uuid
    packing_and_accessor :mode, :uint8
    packing_and_accessor :must_process_in, :uint16
    packing_and_accessor :tear_attachment, :boolean
    packing_and_accessor :condition, :struct32
    
    packed_attribute_filling_initializer
    
    MODES = {
      0x00 => :push,
      0x01 => :pull
    }
    MODE_IDS = MODES.invert
  end
  
  class SubscribeResponse
    include RubyMQ::Packager
  
    packing_and_accessor :result, :uint8
    packing_and_accessor :condition_failure_details, :uint8
    packing_and_accessor :subscription_key, :uuid
    
    packed_attribute_filling_initializer
    
    RESULTS = {
      0x00 => :subscribed,
      0x01 => :authorization_failure,
      0x02 => :no_such_condition_type,
      0x03 => :condition_failure,
      0x04 => :server_is_shutting_down
    }
    RESULT_IDS = RESULTS.invert
  end

  
  class Unsubscribe
    include RubyMQ::Packager
    
    packing_and_accessor :channel, :str16
    packing_and_accessor :subscription_key, :uuid
    
    packed_attribute_filling_initializer
  end

  class UnsubscribeResponse
    include RubyMQ::Packager
  end

  
  class Poll
    include RubyMQ::Packager
  
    packing_and_accessor :subscription_key, :uuid
    packing_and_accessor :bottom_limit, :uint16
    packing_and_accessor :upper_limit, :uint16
    
    packed_attribute_filling_initializer
  end
  
  class PollResponse
    include RubyMQ::Packager
  
    packing_and_accessor :count, :uint16
    
    packed_attribute_filling_initializer
  end

  class Configure
    include RubyMQ::Packager
    
    packing_and_accessor :channel, :str16
    packing_and_accessor :reliable, :boolean
    packing_and_accessor :hope_for_subscribers, :boolean
    packing_and_accessor :publish_subscribe, :boolean
    packing_and_accessor :temparary, :boolean
    packing_and_accessor :private, :boolean
    
    packed_attribute_filling_initializer
  end

  class ConfigureResponse
    include RubyMQ::Packager

    packing_and_accessor :result, :uint8
    
    packed_attribute_filling_initializer
  end

  RubyMQ::Packager.register 0x02, self,
    0x01 => Subscribe,
    0x02 => SubscribeResponse,
    0x03 => Unsubscribe,
    0x04 => UnsubscribeResponse,
    0x05 => Poll,
    0x06 => PollResponse,
    0x07 => Configure,
    0x08 => ConfigureResponse
end
