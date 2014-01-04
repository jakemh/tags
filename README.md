tags
====
tags attempts to efficiently evaluate tag expressions using sorted lists stored in server memory. Based on the work of legendary engineer, hacker, facebook employee, mentor and friend, Marcel G. Laverdet. 

###Example:

```ruby
# send an expression and print resulting topic ids
TagExpressions::Client::send_request("GET", ["LUE - Heartbreaks + Current_Events & Adult"]) do |response|
  p JSON.parse(response)
end

# after creating topic with id 34, topic with tags is added to server and response message is printed
TagExpressions::Client::send_request("PUT", {34 => [:LUE, :Heartbreaks]}) do |response|
  p response
end
```
