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


class NoticedCacheUser
  def initialize
    @cache = NoticedCache.instance User, 'users_changed', 'users'
    
    @cache.define_loader do |cache|
      sleep 10
      cache[:user] = User.find(42)
      @login = cache[:user].login
    end
  end
  
  def test
    @cache.use do
      puts @cache[:user].id
      puts @login
    end
  end
end