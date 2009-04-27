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


require 'sqlite3'

class RubyMQ::Storage::Sqlite
  def initialize path
    @connection = SQLite3::Database.new(path)
    
#    @connection.results_as_hash = true
    
    @connection.execute("PRAGMA count_changes = 0;")
    @connection.execute("PRAGMA synchronous = OFF;")
    
    # 3 minutes
    @connection.busy_timeout(3 * 60 * 1000)
    
    unless @connection.execute("SELECT name FROM sqlite_master WHERE type='table' AND name = 'rubymq_messages'").length == 1
      @connection.execute('PRAGMA encoding = "UTF-8";')
      @connection.execute "CREATE TABLE rubymq_messages (
        id INTEGER PRIMARY KEY,
        channel TEXT,
        message BLOB
        );
      "
    end
    
    @insert = @connection.prepare("INSERT INTO rubymq_messages (channel, message) VALUES (?, ?)")
    @update = @connection.prepare("UPDATE rubymq_messages SET channel = ?, message = ? WHERE id = ?")
    @delete = @connection.prepare("DELETE FROM rubymq_messages WHERE id = ?")
    @load   = @connection.prepare("SELECT id, channel, message FROM rubymq_messages")
    
    @mutex  = Mutex.new
  end
  
  def transaction &block
    @mutex.synchronize do
      @connection.transaction(&block)
    end
  end
  
    # Если не использовать SQLite3::Blob.new, то в базе сохраняется всё, вроде бы нормально (побайтно сравнивал данные),
  # однако загружается оттуда обрезанным - при загрузке ошибка marshal data too short
  # Может быть оно какой-нибудь флаг взводит?
  def insert channel, message
    @insert.execute! channel, SQLite3::Blob.new(Marshal.dump(message)) # execute! is a little bit faster
    @connection.last_insert_row_id
  end

  def update channel, message, id
    @update.execute! channel, SQLite3::Blob.new(Marshal.dump(message)), id
  end
  
  def delete id
    @delete.execute! id
  end
  
  def load
    @load.execute!.collect{|id, channel, message| [id.to_i, channel, Marshal.load(message)]}
  end
end
