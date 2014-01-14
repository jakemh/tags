require_relative 'spec_helper'
require_relative 'models'

describe "General Order of Operation   Tag Evaluation" do
	
	lue = lambda{ TagExpressions.data["LUE"] }
	programming = lambda{ TagExpressions.data["Programming"] }
	java = lambda{ TagExpressions.data["Java"] }
	heartbreaks = lambda{ TagExpressions.data["Heartbreaks"] }
	current_events = lambda{ TagExpressions.data["current_events"] }
	ruby = lambda{ TagExpressions.data["Ruby"] }
	sports = lambda{ TagExpressions.data["Sports"] }


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
		topic3 = Topic::create_with_tags("LUE, Java")
		Order.difference(lue.(), programming.()).should == (lue.() - programming.())
	end

	it 'should allow union' do
		topic1 = Topic::create_with_tags("LUE")
		topic2 = Topic::create_with_tags("Programming")
		topic3 = Topic::create_with_tags("Java")

		Order.union(Order.union(lue.(), programming.()).reverse, java.()).should == (lue.() + programming.() + java.()).sort.reverse

	end

	it 'should allow intersection' do
		topic1 = Topic::create_with_tags("LUE, Programming, Java")
		topic2 = Topic::create_with_tags("Programming, Java")
		topic3 = Topic::create_with_tags("Java, Programming")

		Order.intersection(Order.intersection(lue.(), programming.()), java.()).should == (lue.() & programming.() & java.())
	end

	it 'should handle all at once' do
		topic1 = Topic::create_with_tags("LUE, Programming")
		topic2 = Topic::create_with_tags("Java")
		topic3 = Topic::create_with_tags("Programming, LUE, Heartbreaks")
		topic4 = Topic::create_with_tags("Java, Programming, LUE, Heartbreaks")

		lue_plus_java = Order.union(lue.(), java.()).reverse
		lue_plus_java_minus_heartbreaks = Order.difference(lue_plus_java, heartbreaks.()).reverse

		Order.intersection(programming.(), lue_plus_java_minus_heartbreaks).should == programming.() & lue.() + java.() - heartbreaks.()
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

		lue__plus__java = Order.union(lue.(), java.()).reverse
		lue__plus__java__minus__current_events = Order.difference(lue__plus__java, current_events.()).reverse
		programming__plus__ruby = Order.union(programming.(), ruby.()).reverse
		heartbreaks__minus__sports = Order.difference(heartbreaks.(), sports.()).reverse

		Order.intersection(lue__plus__java__minus__current_events, 
			Order.intersection(programming__plus__ruby, heartbreaks__minus__sports).reverse).should ==
		(lue.() + java.() - current_events.() & programming.() + ruby.() & heartbreaks.() - sports.()).sort.reverse
	end
	# it 'should be able to restrict accumulation' do
	# 	topic1 = Topic::create_with_tags("Programming")
	# 	topic2 = Topic::create_with_tags("Programming")
	# 	topic3 = Topic::create_with_tags("Programming")
	# 	topic4 = Topic::create_with_tags("Programming")
	# 	topic5 = Topic::create_with_tags("Movies")
	# 	topic6 = Topic::create_with_tags("Movies")
	# 	topic7 = Topic::create_with_tags("Movies")

	# 	options = {:accumulate => 5}
	# 	result = Expressions::evaluate("Programming + Movies", options)
	# 	result.should_not == [topic7, topic6, topic5, topic4, topic3, topic2, topic1]
	# 	result.should == [topic7, topic6, topic5, topic4, topic3]

	# end

	# it 'should be able to skip results' do
	# 	topic1 = Topic::create_with_tags("LUE")
	# 	topic2 = Topic::create_with_tags("Programming")
	# 	topic3 = Topic::create_with_tags("Java")
	# 	topic4 = Topic::create_with_tags("Current_Events")
	# 	topic5 = Topic::create_with_tags("Ruby")
	# 	topic6 = Topic::create_with_tags("Movies")
	# 	topic7 = Topic::create_with_tags("Pets")
		
	# 	options = {:skip => 2}
	# 	result = Expressions::evaluate("LUE + Programming + Java + Current_Events + Ruby + Movies + Pets", options)
	# 	result.should_not == [topic7, topic6, topic5, topic4, topic3, topic2, topic1]
	# 	result.should == [topic5, topic4, topic3, topic2, topic1]

	# end
end