require_relative 'spec_helper'
require_relative 'models'

describe "Left to Right Tag Evaluation" do
	
	before(:each) do
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

	it 'should handle complex cases' do
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
