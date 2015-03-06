require_relative 'spec_helper'
require_relative 'models'

describe "Tag Server" do
  before(:each) do
    TagExpressions::Data::reset_tags
    TagExpressions::Data::DB::setup
  end

  after(:each) do
    TagExpressions::Data::Topic.delete_all
    TagExpressions::Data::Tag.delete_all
    TagExpressions::Server::reset_server_data
    TagExpressions::Server::Base::reset_server
  end

  (0..5).each do |trial|
    it "should allow client connection" do
      Thread.new do
        TagExpressions::Server::Base::run_server
      end

      while (true)
        if TagExpressions::Server::Base::server_running
          expect {TagExpressions::Client::send_request(nil, nil) }.to_not raise_error
          break
        end
      end
    end
  end

  (0..5).each do |trial|
    it "should allow client to receive success message on PUT request" do

      Thread.new do
        TagExpressions::Server::handle_requests
      end

      while (true)

        if TagExpressions::Server::Base::server_running
          TagExpressions::Client::send_request("PUT", {35 => [:LUE, :Heartbreaks]}) do |response|
            response.should include TagExpressions::Server::SUCCESS_MESSAGE_PUT
          end
          break
        end
      end
    end
  end

  (0..5).each do |trial|
    it "should allow client to receive error message on PUT request if topic id is blank or nil" do

      Thread.new do
        TagExpressions::Server::handle_requests
      end

      while (true)

        if TagExpressions::Server::Base::server_running
          TagExpressions::Client::send_request("PUT", {nil => [:LUE, :Heartbreaks]}) do |response|
            response.should include TagExpressions::Server::ERROR_MESSAGE_PUT
          end
          break
        end
      end
    end
  end

  (0..5).each do |trial|
    it "should allow client to receive correct data on GET request" do

      topic1 = Topic::create_with_tags("LUE")
      topic2 = Topic::create_with_tags("Programming")
      TagExpressions::Server::reset_server_data

      Thread.new do
        TagExpressions::Server::handle_requests
      end

      while (true)

        if TagExpressions::Server::Base::server_running
          TagExpressions::Client::send_request("GET", ["LUE + Programming"]) do |data|
            JSON.parse(data).should include(topic1, topic2)
          end
          break
        end
      end
    end
  end

end
