require_relative 'data_main'
require_relative 'parse'

module TagExpressions

  ACCUMULATE = 10
  SKIP = 0

  def self.data
    @@data = TagExpressions::Data::tags
  end

  def self.options
    @options ||= {}
    @options[:accumulate] ||= ACCUMULATE
    @options[:skip] ||= SKIP
    return @options
  end

  def self.unions_at_index(sets, operators_list, indices)
    array = []
    sets.each_with_index do |set, j|
      if  operators_list[j] == "+"  and indices[j] >= 0
        array.push(set[indices[j]])
      end
    end
    return array
  end

  def self.unions_empty(operators, indices)
    operators.each_with_index do |op, j|
      return false if op == "+" and indices[j] >= 0
    end
    return true
  end

  def self.build_id_list(tags, operators)
    sets = Array.new( tags.length ){ |tag_index| data[tags[tag_index]] }
    indices = Array.new( tags.length ){ |set_index| sets[set_index].length - 1 }

    candidate_list = []
    return_list = []
    count = 0
    # build return_list until return_list reaches the accumulation threshold
    # or all of the union sets have reached index 0
    while return_list.length <= (options[:accumulate] + options[:skip]) and not unions_empty(operators, indices)
      sets.each_with_index do |set, k|

        if operators[k] == "+"

          ### must ensure sorted order is maintained; otherwise, results may be wrong
          # - find the maximum union size at each cursor; this is the current union reference
          # - if set value at current index is the union set value, then push into candidate list and advance
          # - decrement cursor after each push into candidate list
          # loop while max_union is not nil; ie all of the unions have not reached index 0
          # break when current value (set[indices[k]]) exceeds max_union or an index reaches 0
          while max_union = unions_at_index(sets, operators, indices).max
            if set[indices[k]] == max_union
              candidate_list << set[indices[k]]
              indices[k] -= 1
            end

            break  if set[indices[k]] < max_union or indices[k] <= 0

          end
        else # deductive operators; operator is either "-" or "&"

          # perform task for each candidate in candidate list
          candidate_list.each_with_index do |ref, i|
            backup_to = set.length - 1

            # candidate list serves as reference points for the deductive operators
            # advance set until it is not greater than the reference
            while (ref and set[indices[k]] and set[indices[k]] > ref)
              backup_to = indices[k] if set[indices[k]] == candidate_list.compact.max
              indices[k] -= 1
            end

            # "-" set kills candidate if it is equal to the candidate
            # "&" kills candidate if it is NOT equal to the candidate
            if operators[k] == "-"
              candidate_list[i] = nil if set[indices[k]] == candidate_list[i]
            elsif operators[k] == "&"
              candidate_list[i] = nil if set[indices[k]] != candidate_list[i]
            end

            # after each evaluation of a candidate, deductive set index must be reset in order to evaluate
            # the next value in the candidate list. this could probably be done better
            indices[k] = backup_to
          end
        end
      end

      # at end of each loop, push candidate into return_list
      # candidate will be nil if it was killed by a deductive operator
      candidate_list.each do |ref|
        if return_list.length < (options[:accumulate])
          if (return_list[-1] != ref or options.delete(:include_duplicates))
            count += 1
            if count > options[:skip]
              return_list.push(ref) if ref != nil
            end
          end
        else break
        end
      end

      candidate_list = []

    end
    return return_list
  end

  def self.evaluate(expression, cfg = {})
    @options = cfg
    parsed = Hash[TagExpressions::Parse::tuples_from_string(expression)]
    build_id_list(parsed.keys, parsed.values)
  end
end
