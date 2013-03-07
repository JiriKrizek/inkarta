#!/usr/bin/env ruby
# encoding: UTF-8
require "bundler"

Bundler.require

class NotifClient
  attr_accessor :value, :mail

  def initialize(minimum_value, mail)
    raise ArgumentError("minimum_value must be > 0") unless minimum_value>0
    raise ArgumentError("mail is not a string") unless mail.is_a? String

    self.value = minimum_value
    self.mail  = mail
  end

  def notify(checker)
    if checker.curr_state < checker.prev_state
      puts "Current state changed, ticket was bought: #{checker.curr_state.sum_value-checker.prev_state.sum_value} Kč, new state is #{checker.curr_state.sum_value} Kč" if DEBUG
      if checker.curr_state.sum_value < @value
        puts "WARNING: Credit dropped under limit #{@value} Kč, new state is #{checker.curr_state.sum_value} Kč" if DEBUG

        msg = "Zustatek na karte na vlak klesl pod limit #{@value} Kc. Soucasny zustatek je #{checker.curr_state.sum_value} Kc."
        send_mail(self.mail, msg) unless DEBUG
      end
    elsif checker.curr_state > checker.prev_state
      puts "Current state changed, card credit increased: #{checker.curr_state.sum_value-checker.prev_state.sum_value} Kč" if DEBUG
    else
      puts "State not changed since last check" if DEBUG
    end
  end

private
  def send_mail(to, msg)
    from = 'jkrizek@gmail.com'
    msg = <<END_OF_MESSAGE
To: <#{to}>

#{msg}
END_OF_MESSAGE

    Net::SMTP.start('smtp.klfree.net') do |smtp|
      smtp.send_message msg, from, to
    end
  end
end