require_relative 'request'

require 'socket'
require 'json'

module TagExpressions
	module Client
    	

	
		def self.send_request(type, data = nil)
			socket = TCPSocket.open('localhost', 3001)

				# process data
				request = if type == "PUT"
					TagExpressions::Request::put(data)
				elsif type == "GET"
					TagExpressions::Request::get(data)
				end

				# send data to server
				socket.write (request)

				# receive data from server
				yield socket.read if block_given?
				socket.close
		end

	end
end

# example requests

# send an expression
# TagExpressions::Client::send_request("GET", ["LUE - Heartbreaks + Current_Events & Adult"]) do |response|
# 	p JSON.parse(response)
# end

# created a new topic with tags 
# TagExpressions::Client::send_request("PUT", {34 => [:LUE, :Heartbreaks]}) do |response|

# end