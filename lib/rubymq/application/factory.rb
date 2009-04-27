# 
#  Copyright 2007-2008 Stanislav Senotrusov <senotrusov@gmail.com>
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
 

class RubyMQ::Application::Factory
  def initialize
    @args = {}
    @args[:class] = RubyMQ::Application
    
    @configurations = []
  end
  
  def push_args args
    if args[:greedy_load]
      args[:greedy_load].each do |greedy_load|
        GreedyLoader.push_path "#{args[:name]}_#{greedy_load}".to_sym, Gem.required_location(args[:name].to_s, greedy_load.to_s)
      end
    end

    @args.merge! args
  end
  
  def push_configuration conf
    @configurations << conf
  end
  
  def name
    @args[:name]
  end
  
  def produce(args)
    produced = @args[:class].new(@args.merge(args))
    
    @configurations.each {|conf| conf.call(produced)}
    
    produced.initialize_endpoint_applications
    
    return produced
  end
end
