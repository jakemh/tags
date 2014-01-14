require_relative 'data_main'
require_relative 'parse'

module TagExpressions
    module Order
        ACCUMULATE = 100
        SKIP = 0
        def self.data
            @@data = TagExpressions::Data::tags
        end

        def self.default_options
            {:until_up_to => 0,
             :until_less_than_or_equal_to => 0,
             :skip => SKIP,
             :accumulate => ACCUMULATE,
             :starting_at => -1}
        end

        # use following API:
        # :accumulate => accumulate this many items
        # :skip => do not accumulate until this many matches are found
        # :until_less_than => accumulate until PAST this value
        # :until_up_to => accumulate UP TO this value 
        # :must_accumulate => return false if cannot accumulate this many values 
        def self.update_return_with_options(return_list, ref, count, opt = options)

            return_list_orig_length = return_list.length
            
            if return_list.length < opt[:accumulate] and ref >= opt[:until_up_to]
                if (return_list[-1] != ref or opt[:include_duplicates])
                    count[0] += 1
                    if count[0] > opt[:skip]
                        return_list.push(ref) if ref != nil
                        if opt.has_key? :until_less_than_or_equal_to and opt[:until_less_than_or_equal_to] >= ref
                            return false 
                        end
                    end
                end
            else
                return false
            end
            if opt.has_key?(:must_accumulate) and (return_list.length - return_list_orig_length) < opt[:must_accumulate]
                return false
            end
            true
        end

       def self.union(set0, set1, opt = {})
            opt = default_options.merge(opt)
 
            count = [0]
            return_list = []
            set0_prev_length = 0
            i = [-1, -1]
            
            set0_temp = set0; set1_temp = set1
            set0_proc = set0; set1_proc = set1 #default initialization 
            set0_proc = lambda{ |opt| base(set0_temp, opt).reverse} if !set0.kind_of? Proc
            set1_proc = lambda{ |opt| base(set1_temp, opt).reverse} if !set1.kind_of? Proc

            # inner option is to allow union to convert starting_at value to the accumulate value
            # when it is not the outer call
            if opt.delete(:inner)
                opt[:skip] = opt[:starting_at] * -1  - 1
            end

            while return_list.length < opt[:accumulate] and (i[1] > -ACCUMULATE or i[0] > -ACCUMULATE)
                ref1 = set0_proc.call({:accumulate => 1, :starting_at => i[0], :inner => true})
                ref2 = set1_proc.call({:accumulate => 1, :starting_at => i[1], :inner => true})
                refs = [ref1, ref2]

                if ref1[0] == nil
                    ref = ref2[0]
                    i[1] -= 1
                elsif ref2[0] == nil
                    ref = ref1[0]
                    i[0] -= 1

                elsif ref1[0] > ref2[0]
                    ref = ref1[0]
                    i[0] -= 1
                else 
                    ref = ref2[0]
                    i[1] -= 1
                end

                if ref == nil or update_return_with_options(return_list, ref, count, opt) == false
                    break 
                end
            end
            return return_list
        end

        # id is added to list if set1 val is not equal to reference val
        def self.difference(set0, set1, opt = {})
            return deduction(set0, set1, opt) do |set0, set1|
                 true if set0[0] != set1[0]
            end
        end

        # id is added to list if set1 val is equal to reference val
        def self.intersection(set0, set1, opt = {})
            return deduction(set0, set1, opt) do |set0, set1|
                 true if set0[0] == set1[0]
            end
        end


        # iterate reference list by one
        # advance the set1 until it is less than or equal to the first set
        # yield returns condition
        def self.deduction(set0, set1, opt = {})
            #subtract set1 from set0
            opt = default_options.merge(opt)
            count = [0]
            return_list = []
            set0_prev_length = 0
            i = [opt[:starting_at] || -1, -1]
            
            set0_temp = set0; set1_temp = set1
            set0_proc = set0; set1_proc = set1
            set0_proc = lambda{ |opt| base(set0_temp, opt).reverse} if !set0.kind_of? Proc
            set1_proc = lambda{ |opt| base(set1_temp, opt).reverse} if !set1.kind_of? Proc
            while return_list.length < (opt[:accumulate]) and i[0] > -ACCUMULATE 
                set0 = set0_proc.call({:accumulate => 1, :starting_at => i[0], :inner => true})
                if set0[0]
                   set1 = set1_proc.call({:until_less_than_or_equal_to => set0[0], :inner => true})

                    if yield set0, set1
                        break if update_return_with_options(return_list, set0[0], count, opt) == false
                    end 

                    i[0] -= 1

                else break
                end
            end
            return return_list
        end       

        # iterate a base case (reference to a list from db) that is not associated with a set operator
        def self.base(set0, opt = {})
            opt = default_options.merge(opt)
            count = [0]
            return_list = []
            i = [opt[:starting_at] || -1, -1]
            while return_list.length < (opt[:accumulate]) and i[0] > -ACCUMULATE and set0[i[0]] != nil
                break if update_return_with_options(return_list, set0[i[0]], count, opt) == false
                i[0] -= 1
            end
            return return_list
        end
    end
end



##### some example code ######

ruby = TagExpressions::Order.data["Ruby"]; # p ruby.reverse
adult = TagExpressions::Order.data["Adult"]; # p adult.reverse
# p (ruby + adult).sort.uniq.reverse
air = TagExpressions::Order.data["Air"]; # p air.reverse
aeroplane = TagExpressions::Order.data["Aeroplane"]; #p aeroplane.reverse
album =  TagExpressions::Order.data["Album"];# p album.reverse
# p (ruby + adult).sort.uniq.reverse

room = TagExpressions::Order.data["Room"]; # p room.reverse
# p (aeroplane & air).uniq.sort.reverse
# puts 
#  ruby.reverse
#  adult.reverse

# puts

air_plus_aeroplane = lambda{ |opt| TagExpressions::Order.union(air, aeroplane, opt).reverse }
air_and_aeroplane = lambda{ |opt| TagExpressions::Order.intersection(air, aeroplane, opt).reverse }
ruby_plus_adult = lambda{ |opt| TagExpressions::Order.union(ruby, air_and_aeroplane, opt).reverse }

ruby_and_adult = lambda{ |opt| TagExpressions::Order.intersection_base(ruby, air_and_aeroplane, opt).reverse }
ruby_plus_adult__and__air_plus_aeroplane = lambda{ |opt|  TagExpressions::Order.intersection(ruby_plus_adult, air_plus_aeroplane, opt).reverse }

# p TagExpressions::Order.difference(ruby_plus_adult, air_plus_aeroplane )
# p TagExpressions::Order.union(ruby, adult)
# p ((ruby + adult) - (air + aeroplane)).sort.uniq.reverse
# p ((ruby + adult)).sort.uniq.reverse
# p TagExpressions::Order.intersection(ruby_plus_adult, air_plus_aeroplane)
# p ((ruby - adult) - (ruby & adult)).sort.reverse.uniq

# p "STARTING VERY VERY SLOW EVALUATION"
# p TagExpressions::Order.difference(ruby_plus_adult, ruby_plus_adult__and__air_plus_aeroplane)
# p ((ruby + (air & aeroplane)) - ((ruby + (air & aeroplane)) & (air + aeroplane))).sort{ |a,b| b <=> a }.uniq


