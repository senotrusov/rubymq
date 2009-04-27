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
 


puts ARGV.inspect

parser = ArgvParser.new ARGV

LOG_STORAGES = %w(stdout file sqlite)

parser.heading_option_push "ACTION", "ProcessController action (start/stop/run)"

parser.heading_option_push "[CLASS]", "Class to execute"

parser.heading_option_push "[OPT]...", "Class to execute"


parser.option "-e, --environment NAME",
              "Run in environment (development, production, testing)"
            
parser.option "--name NAME", "Daemon's name" do |value|
  value * 2
#  raise "OUPS"
end
            
parser.option "--working-dir DIRECTORY",
              "Working directory, defaults to ."
            
parser.option "--pid-dir DIRECTORY",
              "PID directory, relative to working-dir, defaults to 'log', fallbacks to '.', may be absolute"
            
parser.option "--pid-file FILE",
              "PID file, defaults to [name].pid, may be absolute path"
            
parser.option "--log-to STORAGE",
              "Logger storage (#{LOG_STORAGES * ", "})"
            
parser.option "--log-level LEVEL",
              "Log level (debug < info < warn < error < fatal)"

parser.option "--log-dir DIRECTORY",
              "Log directory, relative to working-dir, default to 'log', fallbacks to '.', may be absolute"

parser.option "--log-file FILE",
              "Logfile, default to [name].log or [envoronment].log.db, may be absolute path"

parser.option "--term-timeout SECONDS",
              "Termination timeout, default to 30"

parser.option "--optval [SECONDS]"

parser.option "-?, --help",
              "Show this help message"

parser.header << "HEADER"
parser.footer << "FOOTER"

#parser.errors << "FUCK"

#parser.show_options


#parser.show_errors

#puts parser.inspect


parser.tailing_option_push "TAIL1", "Class to execute"

parser.floating_option_push "[FLOAT]...", "Class to execute"

parser.parse!

parser.show_options_and_errors_on_incomplete

puts "\n"

puts parser.inspect


#exit if parser.need_help!

#puts "OK"

  
  
  # TODO: Move this to unittest
  # 
  #  option "-o [VALUE1]..., --[no-]option [VALUE2]...", "COMM", "COND"
  #  => ["o", "option", true, true, true, "COMM", "COND"]
  #  
  #  option("--option-foo [VALUE]")
  #  => [nil, "option-foo", false, true, false, nil, nil]
  #  option("--option [VALUE]...")
  #  => [nil, "option", false, true, true, nil, nil]
  #  option("--option VALUE")
  #  => [nil, "option", false, false, false, nil, nil]
  #  option("--option VALUE...")
  #  => [nil, "option", false, false, true, nil, nil]
  #  option("--option")
  #  => [nil, "option", true, false, false, nil, nil]
  #  option("--[no-]option")
  #  => [nil, "option", true, false, false, nil, nil]
  #
  #  option("-ooo [VALUE]")
  #  => ["ooo", nil, false, true, false, nil, nil]
  #  option("-o [VALUE]...")
  #  => ["o", nil, false, true, true, nil, nil]
  #  option("-o VALUE")
  #  => ["o", nil, false, false, false, nil, nil]
  #  option("-o VALUE...")
  #  => ["o", nil, false, false, true, nil, nil]
  #  option("-o")
  #  => ["o", nil, true, false, false, nil, nil]
  #
  #  option("-ooo, --option [VALUE]")
  #  => ["ooo", "option", false, true, false, nil, nil]
  #  option("-o, --option [VALUE]...")
  #  => ["o", "option", false, true, true, nil, nil]
  #  option("-o, --option VALUE")
  #  => ["o", "option", false, false, false, nil, nil]
  #  option("-o, --option VALUE...")
  #  => ["o", "option", false, false, true, nil, nil]
  #  option("-o, --option")
  #  => ["o", "option", true, false, false, nil, nil]
  #  option("-o, --[no-]option")
  #  => ["o", "option", true, false, false, nil, nil]


# ruby foo.rb first second --optional-one --optional-two OPT_TWO --option OPT --multiple 1 , 2,3, 4 ,5 middle_one middle_two --assign=ASSIGN --assign_two = ASSIGN --assign_three= THREE --assign-four =FOUR --boolean-one --boolean-two --no-boolean-three --string "hello, world" last end "foo bar qux"
# 
# 
# ["first",
#  "second", 
#  "--optional-one", 
#  "--optional-two", "OPT_TWO", 
#  "--option", "OPT", 
#  "--multiple", "1", ",", "2,3,", "4", ",5", 
#  "middle_one", 
#  "middle_two", 
#  "--assign=ASSIGN", 
#  "--assign_two", "=", "ASSIGN", 
#  "--assign_three=", "THREE", 
#  "--assign-four", "=FOUR", 
#  "--boolean-one", 
#  "--boolean-two", 
#  "--no-boolean-three", 
#  "--string", "hello, world", 
#  "last", 
#  "end", 
#  "foo bar qux"]