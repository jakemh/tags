path = File.expand_path("../")
require [path, "lib", "server"].join("/")
require [path, "lib", "client"].join("/")
require [path, "lib", "data"].join("/")
require [path, "lib", "tag_expressions"].join("/")

module Expressions
	
	def self.evaluate(expression)
		TagExpressions::evaluate(expression)
	end
	
end

module Topic
	def self.create_with_tags(tags)
		TagExpressions::Data::Topic.create_with_tags(tags).id
	end
end