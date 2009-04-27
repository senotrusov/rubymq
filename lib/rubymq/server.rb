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


require 'rubymq_facets/thread'
require 'rubymq_facets/more/prioritized_queue'

module RubyMQ::Server
  autoload :ClientPool,    'rubymq/server/client_pool'
  autoload :ClientSession, 'rubymq/server/client_session'
  autoload :Daemon,        'rubymq/server/daemon'
  autoload :Messenger,     'rubymq/server/messenger'
  autoload :Scheduler,     'rubymq/server/scheduler'
  autoload :Subscription,  'rubymq/server/subscription'
  autoload :Switcher,      'rubymq/server/switcher'
  autoload :TransitWatcher,'rubymq/server/transit_watcher'
end  
