require './api.rb'
require 'readline'

HOST = "localhost"
PORT = 9292

loop do
  line = Readline.readline("> ", true)

  tokens = line.split(' ')

  command = tokens.first
  args = tokens.drop(1).join(' ')

  case command
  when "query", "q"
    puts "Querying for interface #{args}..."
    API.query(args)
  when "list", "l"
    puts "Listing info for interface #{args}..."
    API.list(args)
  when "sync", "synch", "s"
    puts "Syncing for interface #{args}..."
    API.sync(args)
  when "publish", "pub", "p"
    puts "Publishing interface #{args}..."
    API.publish(args)
  when "quit", "exit", "x"
    break
  else
    puts "Unknown command #{command}"
  end
end
