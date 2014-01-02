require_relative 'server'
puts "STARTING SERVER"
TagExpressions::Server::handle_requests
Process.daemon
