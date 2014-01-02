require_relative 'spec_helper'

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
end

describe "Tag Server" do
	before(:each) do
		require_relative 'models'
		TagExpressions::Data::reset_tags
		TagExpressions::Data::DB::setup
	end

	after(:each) do
		TagExpressions::Data::Topic.delete_all
		TagExpressions::Data::Tag.delete_all	
	end

	it "should allow client connection" do
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

	it "should receive data from client" do
		# topic1 = Topic::create_with_tags("LUE, Programming")

		Thread.new do
			TagExpressions::Server::handle_requests
		end


	  	while (TagExpressions::Server::data == {})
	  		sleep(0.2)
	  		if TagExpressions::Server::Base::server_running
	  			puts "TEST"

	  			expect {TagExpressions::Client::send_request("PUT", {34 => [:LUE, :Heartbreaks]}) }.to_not raise_error
	  		end
	  	end
	end
end
