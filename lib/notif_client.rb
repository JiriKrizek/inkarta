#!/usr/bin/env ruby
# encoding: UTF-8
require "bundler"

Bundler.require

class NotifClient
  attr_accessor :value, :mail, :charge, :always

  def initialize(minimum_value, mail, hash=nil)
    raise ArgumentError("minimum_value must be > 0") unless minimum_value>0
    raise ArgumentError("mail is not a string") unless mail.is_a? String

    self.charge = false
    self.always = false

    unless hash.nil?
      # Notify on charge
      if hash.has_key?(:charge)
        self.charge = hash[:charge]
      end

      # Always notify on buy
      if hash.has_key?(:always)
        self.always = hash[:always]
      end
    end

    self.value = minimum_value
    self.mail  = mail
  end

  def notify(checker)
    if checker.curr_state < checker.prev_state
      puts "Current state changed, ticket was bought: #{checker.curr_state.sum_value-checker.prev_state.sum_value} Kč, new state is #{checker.curr_state.sum_value} Kč" if DEBUG

      under_limit = checker.curr_state.sum_value < @value
      diff = checker.prev_state.sum_value-checker.curr_state.sum_value

      if @always || under_limit
        puts "WARNING: Credit dropped, new state is #{checker.curr_state.sum_value} Kč" if DEBUG

        if under_limit
          msg = "Zustatek na karte na vlak klesl pod limit #{@value} Kc. Soucasny zustatek je #{checker.curr_state.sum_value} Kc."
        else
          msg = "Zustatek na inkarte se snizil o #{diff} Kc. Soucasny zustatek je #{checker.curr_state.sum_value} Kc."
        end
        print msg if DEBUG
        send_mail(self.mail, msg) unless DEBUG
      end
    elsif checker.curr_state > checker.prev_state
      puts "Current state changed, card credit increased: #{checker.curr_state.sum_value-checker.prev_state.sum_value} Kč" if DEBUG
      if @charge
        msg = "Zustatek na karte na vlak byl navysen o #{checker.curr_state.sum_value - checker.prev_state.sum_value} Kc. Soucasny zustatek je #{checker.curr_state.sum_value}"
        puts "Charge notify is enabled, sending mail:\n\t#{msg}" if DEBUG
        send_mail(self.mail,msg) unless DEBUG
      end
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