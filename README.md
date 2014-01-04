tags
====
tags attempts to efficiently evaluate tag expressions using sorted lists stored in server memory. Based on the work of legendary engineer, hacker, facebook employee, mentor and friend, Marcel G. Laverdet. 

###Example:

`ruby lib/start_server.rb`

```ruby
# send an expression and print resulting topic ids
TagExpressions::Client::send_request("GET", ["LUE + Current_Events & Programming"]) do |response|
  p JSON.parse(response) # => [8, 7, 4, 1]
end

# after creating topic with id 34, topic with tags is added to server and response message is printed
TagExpressions::Client::send_request("PUT", {34 => [:LUE, :Programming]}) do |response|
  p response # => "Success\nSuccess"
end
```


####TODO:

Currently, tags only supports left to right evaluation. eg `"LUE  - Current_Events & Programming - Java"` should be evaluated as `"(LUE - Current_Events) & (Programming - Java)"` but is actually evaluated as `"((LUE  - Current_Events) & Programming) - Java"`. Ideally, both methods would be available to the user. 
