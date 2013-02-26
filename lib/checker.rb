#!/usr/bin/env ruby
# encoding: UTF-8
class Checker
  attr_reader :curr_state, :prev_state

  def initialize
    @observers = []
  end

  def add_observer(observer)
    raise ArgumentError.new("Add observer #{observer} failed - not NotifClient object") unless observer.is_a? NotifClient

    @observers << observer
  end

  def notify_observers
    @observers.each do |o|
      o.notify(self)
      puts "notifying #{o.mail}" if DEBUG
    end
  end

  def run
    result = State.find(:all, :order => "id desc", :limit => 2)
    @curr_state = result[0]
    @prev_state = result[1]

    self.notify_observers
  end
end