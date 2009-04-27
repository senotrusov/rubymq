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
 

class RubyMQ::Application::SchedulingConsumer
  def initialize(application, endpoint, args)
    @schedule = RubyMQ::Application::Schedule.new(args)
    @application = application
    @endpoint = endpoint
  end
  
  attr_reader :schedule
  
  [:id, :name, :next_run, :last_run_at].each do |name|
    class_eval <<-PROXY_METHODS, __FILE__, __LINE__
      def #{name}
        @schedule.#{name}
      end
    PROXY_METHODS
  end

  [:last_run_at=, :executed=, :will_be?].each do |name|
    class_eval <<-PROXY_METHODS, __FILE__, __LINE__
      def #{name}(value)
        @schedule.#{name}(value)
      end
    PROXY_METHODS
  end

  def process_message message, sequence_number
    @endpoint.process_message message, sequence_number, self
  end
  
  def channel
    "/applications/#{@application.name}/schedules/#{@schedule.id.to_s}"
  end
  
  def inspect
    "#{@application.name}/#{@schedule.name} (#{@schedule.id.to_s})"
  end
  
end
