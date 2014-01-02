module TagExpressions
	module Request

		def self.put(data)
			["PUT", data.to_json].join(" ")
		end

		def self.get(data)
			["GET", data.to_json].join(" ")
		end

		def self.handle_request(request)
			if request != nil
				request_data = request.split(" ", 2)
				request_type = request_data[0]
				raw_data = request_data[1]
				data = nil
				if request_type == "GET"
					data = JSON.parse(raw_data)
				elsif request_type == "PUT" or request_type == "POST"
					data = JSON.parse(raw_data)
				end

				yield(data, request_type)
			end
		end
	end
end