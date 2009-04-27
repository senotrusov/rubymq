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
 

class RubyMQ::Application::Schedule
  attr_accessor :id, :name, :args
  attr_accessor :active, :active_since, :active_till, :interval
  attr_accessor :last_run_at, :executed

  def initialize(args)
    @id = args.delete(:id) || RubyMQ::UUID.new
    @name = args.delete :name
    
    @active = args.delete(:active) == false ? false : true
    @active_since = args.delete :active_since
    @active_till = args.delete :active_till
    @interval = args.delete :interval
    
    @args = args
  end
  
  def will_be? time_now
    @active && (!@active_till || time_now < @active_till)
  end
  
  # active_since in included in interval, and active_till is not.
  #
  # since       till
  # @-----------O
  def next_run
    return nil unless active

    # - - -
    if !active_since && !active_till && !interval
      return @executed ? nil : @last_run_at
      
    # - - +
    elsif !active_since && !active_till && interval
      return @last_run_at + interval
      
    # - + -
    elsif !active_since && active_till && !interval
      return nil if @last_run_at >= active_till
    
      return @executed ? nil : @last_run_at
    
    # - + +
    elsif !active_since && active_till && interval
      return nil if @last_run_at >= active_till

      return @last_run_at + interval

    # + - -
    elsif active_since && !active_till && !interval
      return @executed ? nil : active_since
    
    # + - +
    elsif active_since && !active_till && interval 
      return @last_run_at < active_since ? active_since : @last_run_at + interval

    # + + -
    elsif active_since && active_till && !interval
      return (@last_run_at >= active_till || @executed) ? nil : active_since

    # + + +
    elsif active_since && active_till && interval
      return nil if @last_run_at >= active_till
      
      return @last_run_at < active_since ? active_since : @last_run_at + interval
    end
  end
end
