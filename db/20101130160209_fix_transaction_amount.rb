class FixTransactionAmount < ActiveRecord::Migration
  def self.up
    change_column :chargify_transactions, :amount, :decimal, :precision=> 14, :scale => 2
  end

  def self.down
  end
end
