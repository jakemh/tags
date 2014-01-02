module TagExpressions
  module Parse

    REGEX_OPS = '[\|\+\-\&]'
    SPLIT_REGEX = "(#{REGEX_OPS})"
    SPLIT_REGEX_WHITESPACE = "\s+(#{REGEX_OPS})\s+"

    def self.options
      @options ||= {}
    end

    def self.tuples_from_string(tag_list)
      parsed_expression = parse_expression(tag_list)
      formatted_expression = fixed_expression_array(parsed_expression)
      tuples = tuple_list(formatted_expression)
    end

    # looks for consecutive operators and subsitutes in the first 
    # prevents expression from being broken e.g. java++ruby => java+ruby
    def self.fix_operator_syntax(expression_string)
      expression_string.scan(/(?<!\\)#{REGEX_OPS}{2,}/).each do |ops|
        expression_string.gsub!(ops, ops[0])
      end
    end

    def self.fix_operator_syntax_whitespace(expression_string)
      expression_string.scan(/(?<!\\)\s#{REGEX_OPS}{2,}\s/).each do |ops|
        expression_string.gsub!(ops, " #{ops.strip[0]} ")
      end
    end

    # splits string at valid operators
    def self.parse_expression(tag_list)
      expression_string = tag_list
      expression_array = []
      if !options.delete(:use_whitespace)
        fix_operator_syntax(expression_string)
        expression_array = expression_string.split(/(?<!\\)#{SPLIT_REGEX}/)
      else
        fix_operator_syntax_whitespace(expression_string)
        expression_array = expression_string.split(/(?<!\\)#{SPLIT_REGEX_WHITESPACE}/)
      end
      return unescape_tags(expression_array)
    end

    # looks for operators preceded by backslashes and replaces with empty string
    # this returns string to original unescaped form, enabling tag operators inside of strings 
    def self.unescape_tags(expression_array)
      if !options.delete(:use_whitespace)
        unescape_with_regex(expression_array, /\\(?=#{REGEX_OPS})/)
      else
        unescape_with_regex(expression_array, /\\(?=\s)/)
      end
      return expression_array
    end

    # replaces matches with sub value 
    def self.unescape_with_regex(input, regex, sub = "")
      input.map!{|e| e.gsub(e.scan(regex)[0] || sub, sub)}.reject!(&:empty?)
    end

    # insert + if first character is not an operator
    # meaning that in default case, the first tag will be handled as union, or :any
    def self.fixed_expression_array(expression_array)
      expression_array.insert(0, "+") if /^#{REGEX_OPS}/ !~ expression_array[0] 
      return expression_array
    end

    # converts split expression array into tuples in the form [operator, tag]
    # provides option of using default ActiveRecord chaining order using :default_chaining option 
    def self.tuple_list(expression_array)
      expression_array = expression_array.each_slice(2).map { |op, tag|  [tag.strip, op.strip]}
    end

  end
end
# tag_list = "LUE+Heartbreaks-Programming"
#  parsed_expression = Parse.parse_expression(tag_list)
#       formatted_expression = Parse.fixed_expression_array(parsed_expression)
#      p tuples = Parse::tuple_list(formatted_expression)
