require_relative 'data_main'
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
                                lists.push( list )
                        end
                end

                return { :tags => lists.map{ |e| e.map{ |tag, op| tag } }, :operators_list => lists.map{ |e| e.map{ |tag, op| op } } }
        end

        # check if id is "still alive", ie it hasn't been ruled out yet by "-"" or "&"
        # if the id == reference at "-" then it's being deducted out (return false)
        # if the id != eference at "&", then it's not intersecting (return false)
        def self.check_condition(set, type, index, reference)
                if type == "+"
                        true
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

        # core logic to build id set
        def self.build_id_list(tags, operators_list)

                # each set is an array of topics with each tag
                # operators are set of operators that corresponds to current set 
                # indices are current index of each set
                return_list = []
                sets = Array.new( tags.length ){ |set_index| data[tags[set_index]] }
                operators = operators_list
                indices = Array.new( tags.length ){ |i| sets[i].length - 1 }
                      
                # iterate from end to allow for ascending sort, resulting in cheap insertions (most often pushes)
                i = sets[0].length - 1

                # iterate until you accumulate your total OR you reach the end of your reference set 
                # decrement i each iteration
                # reference is topic id that all sub iterators will compare to

                while return_list.length < ACCUMULATE and (i >= 0)

                reference = sets[0][i]

                # for each increment along the reference set, we must advance all the sub sets
                # advance until the current index is NOT greater than the reference 
                sets.each_with_index do |set, k|

                        while (sets[k][indices[k]] != nil and sets[k][indices[k]] > reference)
                                indices[k] -= 1
                        end
                end

                        # after advancing the sub sets, we can check their conditions as described in check_condition
                        # if all condition tests are passed, then push into array
                        return_list.push(reference) if condition(sets, indices, operators, reference)
                        i -= 1
                end  
                return return_list
        end

        # inputted string will be parsed into the following:
        # expression = {"LUE" => "+", "Programming" => "+", "Heartbreaks" => "&","Music" => "&","Current_Events" => "+" ,"Relationships" => "-"}
        # formatter will conver this into:
        # {:tags=>[["LUE", "Heartbreaks", "Music", "Relationships"], ["Programming", "Heartbreaks", "Music", "Relationships"], ["Current_Events", "Relationships"]], :operators_list=>[["+", "&", "&", "-"], ["+", "&", "&", "-"], ["+", "-"]]}
        # iterates arrays from end to allow for cheaper insertion 
        def self.evaluate(expression)
                formatted_data = format(TagExpressions::Parse::tuples_from_string(expression))
                tags = formatted_data[:tags]
                operators_list = formatted_data[:operators_list]
                return_list = []

                # iterate each union set as described in #format
                (0...operators_list.length).each do | j |
                        return_list.concat build_id_list(tags[j], operators_list[j])
                end

                return return_list.sort{|b,a| a <=> b}.uniq
        end
end

# example (should provide same result): 
# p TagExpressions.evaluate("Aeroplane + Room - Album - Adult & Air").sort{|b,a| a <=> b}.uniq
# p (((TagExpressions.data["Aeroplane"] + TagExpressions.data["Room"]) - TagExpressions.data["Album"]) - TagExpressions.data["Adult"] & TagExpressions.data["Air"]).sort!{|a,b| b<=>a}
