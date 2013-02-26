#!/usr/bin/env ruby
# encoding: UTF-8

DB_PATH = 'data/states.db'

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
  include Comparable
  attr_accessible :datetime, :card, :wallet

  def <=>(another_state)
    if self.card > another_state.card
      return 1
    elsif self.card < another_state.card
      return -1
    end
    return 0
  end

  def sum_value
    card+wallet
  end
end