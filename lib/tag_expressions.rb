require_relative 'data'
require_relative 'parse'

module TagExpressions
	ACCUMULATE = 100

	def self.data()
		@@data = TagExpressions::Data::tags
	end

	# convert hash into sub lists of operators and tags
	# each set is independent of other unions, ie unions are handled independently
	# eg LUE + Programming & Heartbreaks & Music + Current_Events - Relationships
	# will break it into the following lists:
	# LUE & Heartbreaks & Music - Relationships
	# Programming & Heartbreaks & Music - Relationships
	# Current_Events - Relationships
	def self.format(expression)
		lists = []
		expression.each_with_index do |(k,v), i|
			if v == "+"
				list = expression.to_a[i..-1]
				list.each_with_index do |(tag, op), j|
					list.delete_at(j) if op == "+" and j > 0
				end
				lists.push(Hash[list])
			end
		end

		return {:tags => lists.map{|hash| hash.keys}, :operators_list => lists.map{|hash| hash.values}}
	end

	# check if id is "still alive", ie it hasn't been ruled out yet by a - or a &
	# if the id is == to a reference at a - then it's being deducted out
	# if the id is != to a referene at a &, then it's not intersecting
	def self.check_condition(set, type, index, reference)
		if type == "+"
			return true
		elsif type == "-"
			set[index] != reference
		elsif type == "&"
			set[index] == reference
		end
	end

	# if the condition is true, keeping going, otherwise return false 
	def self.condition(sets, indices, operators, reference)
		operators.each_with_index do |type, i|
			if check_condition(sets[i], type, indices[i], reference ) == true
				next
			else return false
			end
		end

		return true
	end

	# inputted string will be parsed into the following:
	# expression = {"LUE" => "+", "Programming" => "+", "Heartbreaks" => "&","Music" => "&","Current_Events" => "+" ,"Relationships" => "-"}
	# formatter will conver this into:
	# {:tags=>[["LUE", "Heartbreaks", "Music", "Relationships"], ["Programming", "Heartbreaks", "Music", "Relationships"], ["Current_Events", "Relationships"]], :operators_list=>[["+", "&", "&", "-"], ["+", "&", "&", "-"], ["+", "-"]]}
	# iterates arrays from end to allow for cheaper insertion 
	def self.evaluate(expression)

		formatted_data = format(TagExpressions::Parse::tuples_from_string(expression))
		tags = formatted_data[:tags]; operators_list = formatted_data[:operators_list]
		
		return_list = []

		# iterate sublists of operators (or tags)
		operators_list.each_with_index do |operators, operators_index|
			sets = Array.new(tags[operators_index].length){|set_index| data[tags[operators_index][set_index]]}
			indices = Array.new(tags[operators_index].length){ |i| sets[i].length - 1}
			i = sets[0].length - 1

			# iterate until you accumulate your total OR you reach the end of your reference set 
			# increment i each iteration
			while return_list.length < ACCUMULATE and (i >= 0)

				reference = sets[0][i]

				# for each increment along the reference set, we must advance all the sub sets
				# advance until the current index is NOT greater than the reference 
				sets.each_with_index do |set, j|

					if reference != nil and indices[j] >= 0 and sets[j][indices[j]] > reference
						while (sets[j][indices[j]] != nil and sets[j][indices[j]] > reference)
							indices[j] -= 1
						end
					end
				end

				# after advancing the sub sets, we can check their conditions as described in check_condition
				if condition(sets, indices, operators, reference) == true
					if reference != nil
						return_list.push(reference)
					elsif sets[0][i] != nil 
						return_list.push(sets[0][i]) # then all remaining from set_0 must be diffs
					end
				end
				
				i -= 1
			end
		end
		return return_list.sort{|a,b| b<=>a}.uniq
	end
end

# example: 
# p TagExpressions.evaluate("Aeroplane + Room - Album - Adult & Air")
# p (((TagExpressions.data["Aeroplane"] + TagExpressions.data["Room"]) - TagExpressions.data["Album"]) - TagExpressions.data["Adult"] & TagExpressions.data["Air"]).sort!{|a,b| b<=>a}
