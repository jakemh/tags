path = File.expand_path('../lib', File.dirname(__FILE__))

require [path, "data"].join("/")

TagExpressions::Data::DB::sqlite_path=(File.expand_path('../spec/db/sqlite.db', File.dirname(__FILE__)))
TagExpressions::Data::DB::connect_db

require [path, "tag_expressions"].join("/")
require [path, "server"].join("/")
require [path, "client"].join("/")
module Expressions

  def self.evaluate(expression, options = {})
    TagExpressions::evaluate(expression, options)
  end

end

module Topic
  def self.create_with_tags(tags)
    TagExpressions::Data::Topic.create_with_tags(tags).id
  end
end
