#!/usr/bin/env ruby
# encoding: UTF-8
require "bundler"
require "date"

Bundler.require

DB_PATH = 'data/states.db'
DEBUG = false

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => DB_PATH
)

unless File.exists?(DB_PATH)
  ActiveRecord::Schema.define do
    create_table :states, force: true do |t|
      t.datetime :datetime
      t.integer :card
      t.integer :wallet
    end
  end
end

class State < ActiveRecord::Base
  attr_accessible :datetime, :card, :wallet
end