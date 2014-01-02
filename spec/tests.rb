require_relative 'spec_helper'
require_relative 'models'

describe "Tag Evaluation" do
	before(:each) do
		require_relative 'models'
		TagExpressions::Data::reset_tags
		TagExpressions::Data::DB::setup
	end

	after(:each) do
		TagExpressions::Data::Topic.delete_all
		TagExpressions::Data::Tag.delete_all
	end

	it 'should allow difference' do
		topic1 = Topic::create_with_tags("LUE, Programming")
		topic2 = Topic::create_with_tags("LUE, Programming")
		topic3 = Topic::create_with_tags("LUE, Programming, Java")
		result = Expressions::evaluate("LUE - Java")
		
		result.should include(topic1, topic2) 
		result.should_not include(topic3) 
	end

	it 'should allow union' do
		topic1 = Topic::create_with_tags("LUE")
		topic2 = Topic::create_with_tags("Programming")
		topic3 = Topic::create_with_tags("Java")
		result = Expressions::evaluate("LUE + Programming + Java")

		result.should include(topic1, topic2, topic3) 
	end

	it 'should allow intersection' do
		topic1 = Topic::create_with_tags("LUE, Programming, Java")
		topic2 = Topic::create_with_tags("Programming, Java")
		topic3 = Topic::create_with_tags("Java, Programming")
		result = Expressions::evaluate("LUE & Programming & Java")

		result.should == [topic1]
	end

	it 'should handle all at once from left to right' do
		topic1 = Topic::create_with_tags("LUE, Programming")
		topic2 = Topic::create_with_tags("Java")
		topic3 = Topic::create_with_tags("Programming, LUE, Heartbreaks")
		topic4 = Topic::create_with_tags("Java, Programming, LUE, Heartbreaks")
		result = Expressions::evaluate("Programming & LUE + Java - Heartbreaks")

		result.should include(topic1, topic2)
		result.should_not include(topic3, topic4)
	end

	it 'should handle complex cases from left to right' do
		topic1 = Topic::create_with_tags("LUE, Programming")
		topic2 = Topic::create_with_tags("Java, Programming")
		topic3 = Topic::create_with_tags("Programming, LUE, Heartbreaks")
		topic4 = Topic::create_with_tags("Java, Programming, LUE, Heartbreaks")
		topic5 = Topic::create_with_tags("Current Events, Programming, Java, Ruby")
		topic6 = Topic::create_with_tags("Ruby, Sports, Heartbreaks, Programming")
		topic7 = Topic::create_with_tags("LUE")
		topic8 = Topic::create_with_tags("Java, Current_Events, LUE, Heartbreaks")
		topic9 = Topic::create_with_tags("LUE, Current Events, Programming, Java, Ruby, Heartbreaks")
		topic10 = Topic::create_with_tags("LUE, Current Events, Programming, Java, Ruby")

		
		result = Expressions::evaluate("LUE + Java - Current_Events & Programming + Ruby & Heartbreaks - Sports")
		result.should include(topic3, topic4, topic9)
		result.should_not include(topic1, topic2, topic5, topic6, topic7, topic8, topic10)
	end
end

describe "Tag Server" do
	before(:each) do
		TagExpressions::Data::reset_tags
		TagExpressions::Data::DB::setup
	end

	after(:each) do
		TagExpressions::Data::Topic.delete_all
		TagExpressions::Data::Tag.delete_all	
		TagExpressions::Server::reset_server_data
		TagExpressions::Server::Base::kill_server
		TagExpressions::Server::Base::reset_server


	end

	it "should allow client connection" do
		puts "allow connection"
		 t = Thread.new do
			TagExpressions::Server::Base::run_server
		end

	  	while (true)
	  		sleep(0.2)
	  		if TagExpressions::Server::Base::server_running
	  			expect {TagExpressions::Client::send_request(nil, nil) }.to_not raise_error
	  			break
	  		end
	  	end
	end

	it "should allow client to receive data on GET request" do
		puts "allow get"

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
