#!/usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'action_view'

class Operation
include ActionView::Helpers::DateHelper
  def initialize(date, operation, value, value_ep, value_ep_new, place)
    @date = date
    @operation = operation
    @value = value
    @value_ep = value_ep
    @value_ep_new = value_ep_new
    @place = place
  end

  def to_s
    "Date: #{@date} (#{time_ago_in_words(Time.parse(@date.to_s))} ago)\n\toperation: #{@operation}\n\tvalue: #{@value}\t value_ep: #{@value_ep}\t value_ep_new: #{@value_ep_new}\n\tplace: #{@place}"
  end
end