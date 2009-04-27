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
 

class RubyMQ::Application::Scheduler
  def initialize(application, client, state_file)
    @application = application
    @logger = application.logger
    @client = client
    @state_file = state_file
    
    @must_terminate = false
    
    @mutex = Mutex.new
    @schedules_change = ConditionVariable.new

    @time_now = File.exists?(@state_file) ? Marshal.restore(File.read(@state_file)) : Time.now

    @schedules = []
    @application.only_endpoints_list.each do |endpoint|
      endpoint.schedules_list.each do |schedule|
        if schedule.will_be? @time_now
          schedule.last_run_at = @time_now
          @schedules.push(schedule)
        end
      end
    end
    
    @thread = Thread.new_with_exception_handling(@logger, lambda {|exception| @application.reape! "scheduler_thread, #{exception.class}: #{exception.message}"}) {thread}
  end
  
  def terminate
    @must_terminate = true
    @mutex.synchronize { @schedules_change.signal }
  end
  
  def join
    @thread.join
  end

  private
  
  def thread
    loop do
      @mutex.synchronize do
        @time_now = Time.now
        nearest_next_run = nil

        @schedules.delete_if do |schedule|
          schedule.last_run_at = @time_now unless schedule.last_run_at

          if (next_run = schedule.next_run)
            if next_run <= @time_now
              @logger.debug("Schedule to be executed: #{schedule.inspect} (artificial time: #{@time_now}, planned run: #{next_run})")

              schedule.executed = true
              schedule.last_run_at = @time_now

              execute schedule
            end

            nearest_next_run = next_run if !nearest_next_run || next_run < nearest_next_run
            false          
          else
            @logger.debug "Schedule was removed from list due no planned runs in the future: #{schedule.inspect} (artificial time: #{@time_now})"
            true
          end
        end

        if !nearest_next_run
          @schedules_change.wait(@mutex)
        elsif nearest_next_run > (tn = Time.now)
          # TODO do this without spawning temporary thread each time. Say Thread.stop, Thread.run may help us
          @schedules_change.wait_and_broadcast_on_timeout(@mutex, nearest_next_run - tn)
        end

      end
      break if @must_terminate
    end
  ensure
    File.write @state_file, Marshal.dump(@time_now)    
  end
  
  def execute schedule
    @client.message schedule.channel do |message|
      message[:schedule] = schedule.schedule
    end
  end
  
end