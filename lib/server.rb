require_relative 'request'
require_relative 'data_main'
require_relative 'tag_expressions'
require 'socket'
require 'json'


module TagExpressions
  module Server

    SUCCESS_MESSAGE_PUT = "SUCCESS"
    ERROR_MESSAGE_PUT = "ERROR"

    def self.data
      @@data ||= TagExpressions::Data::tags
    end

    def self.reset_server_data
      @@data = TagExpressions::Data::tags
    end

    def self.add_data(tag, topic_id)
      begin
        if topic_id == nil or topic_id == ""
          raise "Error"
        end
        data[tag].push(topic_id.to_i)
        return true
      rescue Exception
        return false
      end

    end

    def self.handle_requests
      Base::run_server do |session|
        TagExpressions::Request::handle_request(session.gets) do |client_data, type|
          if type == "PUT"
            topic = client_data.keys[0]
            client_data[topic].each do |tag|
              if add_data(tag, topic)
                session.puts (SUCCESS_MESSAGE_PUT)
              else session.puts(ERROR_MESSAGE_PUT)
              end
            end
          elsif type == "GET"
            result = TagExpressions::evaluate(client_data[0])
            session.write(result)
          end
        end
      end
    end

    module Base
      PORT = 3001
      HOST = 'localhost'

      def self.server
        @@server ||= TCPServer.open(HOST, PORT)
      end

      def self.reset_server
        @@server_running = false
        if @@server
          @@server.close
        end
        @@server = TCPServer.open(HOST, PORT)
      end

      def self.server_running
        @@server_running ||= false
      end

      def self.kill_server
        @@server.close
        @@server_running = false
        @@server = nil
      end

      def self.run_server

        while (true)
          @@server_running = true
          # puts "SERVER SHOULD BE RUNNING"
          Thread.start(server.accept) do |session|
            yield session if block_given?
            session.close
          end
        end
      end

    end
  end
end

# how to start server:
# TagExpressions::Server::handle_requests
