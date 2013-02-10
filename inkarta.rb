#!/usr/bin/env ruby
#

require 'httparty'
require 'net/https'
require 'uri'

require './credentials.rb'

uri = 'https://moje.inkarta.cz:443/Account/LogOn'

form_data = {
  'CardNumberPart1' => Credentials::CLIENT_USER[0],
  'CardNumberPart2' => Credentials::CLIENT_USER[1],
  'CardNumberPart3' => Credentials::CLIENT_USER[2],
  'CardNumberPart4' => Credentials::CLIENT_USER[3],
  'Password'        => Credentials::CLIENT_PASS}

response = HTTParty.post(uri, :body => form_data)

cookie = response.request.options[:headers]['Cookie']
puts cookie

url_status = 'https://moje.inkarta.cz/Card/EPTransactions'
response_status = HTTParty.get(url_status, :headers => {'Cookie' => cookie})
puts response_status.body