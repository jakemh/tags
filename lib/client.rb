require_relative 'request'

require 'socket'
require 'json'

module TagExpressions
	module Client
		
		def self.socket
			@@s = TCPSocket.open('localhost', 3001)
		end

		def self.send_request(type, data = nil)
			request = if type == "PUT"
				TagExpressions::Request::put(data)
			elsif type == "GET"
				TagExpressions::Request::get(data)
			end
			socket.print(request)
			socket.close
		end

	end
end

# example requests

# send an expression
# TagExpressions::Client::send_request("GET", ["LUE - Heartbreaks + Current_Events & Java"])

# created a new topic with tags 
# TagExpressions::Client::send_request("PUT", {34 => [:LUE, :Heartbreaks]})