tags
====
tags attempts to efficiently evaluate tag expressions using sorted lists stored in server memory. Speed of evaluation is independent of the number of tags in the database. Based on the work of legendary engineer Marcel G. Laverdet. Both left to right evaluation and order of operations with sub-expressions are supported.

###Example:

`ruby lib/start_server.rb`

```ruby
# send an expression and print resulting topic ids
TagExpressions::Client::send_request("GET", ["Sports + Current_Events & Programming"]) do |response|
  p JSON.parse(response) # => [8, 7, 4, 1]
end

# after creating topic with id 34, topic with tags is added to server and response message is printed
TagExpressions::Client::send_request("PUT", {34 => [:Sports, :Programming]}) do |response|
  p response # => "Success\nSuccess"
end
```

#TODO

improve efficiency of subqueries and distribute as ruby gem. 
