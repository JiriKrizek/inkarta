#!/usr/bin/env ruby
# encoding: UTF-8

Bundler.require

require "bundler"
require "date"
require 'httparty'
require 'net/https'
require 'net/smtp'
require 'nokogiri'
require 'uri'
require_relative 'lib/checker'
require_relative 'lib/credentials'
require_relative 'lib/operation'
require_relative 'lib/notif_client'
require_relative 'lib/state'

DEBUG = false

class InKarta
  def initialize(user_id, user_passwd)
    @user_id = user_id
    @user_passwd = user_passwd
  end

  def load_cookie
    uri = 'https://moje.inkarta.cz:443/Account/LogOn'

    form_data = {
      'CardNumberPart1' => @user_id[0],
      'CardNumberPart2' => @user_id[1],
      'CardNumberPart3' => @user_id[2],
      'CardNumberPart4' => @user_id[3],
      'Password'        => @user_passwd
    }

    begin
      response = HTTParty.post(uri, :body => form_data)
    rescue SocketError => e
      STDERR.puts e
      return nil
    end
    if response.code != 200
      STDERR.puts "Response code is not OK (Error #{response.code})"
      return nil
    end

    last_uri = response.request.last_uri.to_s
    if last_uri != 'https://moje.inkarta.cz/Card/Info'
      STDERR.puts "Cookie not returned, probably invalid card id or password"
      return nil
    end

    if response.request.options[:headers].nil?
      STDERR.puts "Headers are empty"
      return nil
    end

    @cookie = response.request.options[:headers]['Cookie']
  end

  def get_card_value
    parse_html_to_int('//*[@id="data2"]/p[1]/strong[1]/text()')
  end

  def get_wallet_value
    parse_html_to_int('//*[@id="data2"]/p[1]/strong[2]/text()')
  end

  def get_transactions
    transactions = []

    xpath='//*[@id="data2"]/table/tr'
    table=@page.xpath(xpath)

    table.each {|t|
      date = t.xpath('td[1]/text()').to_s
      next if date.empty?
      date = DateTime.strptime(date, '%d.%m.%Y %H:%M:%S')
      operation = t.xpath('td[2]/text()').to_s
      detail = t.xpath('td[3]/text()').to_s
      value = to_int(t.xpath('td[4]/text()').to_s)
      value_ep = to_int(t.xpath('td[5]/text()').to_s)
      value_ep_new = to_int(t.xpath('td[6]/text()').to_s)
      place = t.xpath('td[7]/text()').to_s

      operation += " (#{detail})" unless detail.empty?

      transactions << Operation.new(date, operation, value, value_ep, value_ep_new, place)
    }
    transactions
  end

private
  def get_ep_trans_page
    if @cookie.nil?
      STDERR.puts "Cookie is not set, run load_cookie method first."
    end
    unless @page
      url_status = 'https://moje.inkarta.cz/Card/EPTransactions'
      response_status = HTTParty.get(url_status, :headers => {'Cookie' => @cookie})
      @page = Nokogiri::HTML(response_status.body)
    end
    @page
  end

  def parse_html_to_int(xpath)
    get_ep_trans_page()

    to_int(@page.xpath(xpath).to_s)
  end

  def to_int(string)
    Integer(string.split(",").first)
  end

end

ik = InKarta.new(Credentials::CLIENT_USER, Credentials::CLIENT_PASS)
if ik.load_cookie.nil?
  STDERR.puts "Could not load cookie. Exitting"
  exit 1
end

if DEBUG
  puts "Aktualni hodnota penezenky v cipu karty: \t#{ik.get_card_value} Kč"
  puts "Aktualni hodnota EP k prevodu: \t\t\t#{ik.get_wallet_value} Kč"
end

prevStates = State.find(:all, :order => "id desc", :limit => 2)
p1 = prevStates[0]
p2 = prevStates[1]

state = State.new

state.datetime = Time.new()
state.card = ik.get_card_value
state.wallet = ik.get_wallet_value

if p1.sum_value == p2.sum_value && p2.sum_value == state.sum_value
  print "States are the same" if DEBUG
else
  print "States differ" if DEBUG

  state.save
end



checker = Checker.new()
checker.add_observer(NotifClient.new(100, Credentials::MAIL[0], :charge => true, :always => true))
checker.add_observer(NotifClient.new(70, Credentials::MAIL[1]))

checker.run