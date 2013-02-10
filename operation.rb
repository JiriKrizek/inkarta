#!/usr/bin/env ruby
# encoding: UTF-8

class Operation
  def initialize(date, operation, value, value_ep, value_ep_new, place)
    @date = date
    @operation = operation
    @value = value
    @value_ep = value_ep
    @value_ep_new = value_ep_new
    @place = place
  end

  def to_s
    "Date: #{@date}\n\toperation: #{@operation}\n\tvalue: #{@value}\t value_ep: #{@value_ep}\t value_ep_new: #{@value_ep_new}\n\tplace: #{@place}"
  end
end