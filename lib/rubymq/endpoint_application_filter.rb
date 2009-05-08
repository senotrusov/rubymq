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

class RubyMQ::EndpointApplicationFilter
  def initialize call_method, options
    @call_method = call_method

    @only = options[:only]
    @only = [@only] if @only && !@only.kind_of?(Array)
    
    @except = options[:except]
    @except = [@except] if @except && !@except.kind_of?(Array)
  end

  def suitable?(process_method)
    @only && @only.include?(process_method.to_sym) ||
    @except && !@except.include?(process_method.to_sym) ||
    !@only && !@except
  end

  attr_reader :call_method
end