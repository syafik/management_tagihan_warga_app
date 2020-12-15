# frozen_string_literal: true

class CreateCashTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :cash_transactions do |t|
      t.datetime :transaction_date
      t.integer :transaction_type
      t.float :total
      t.integer :month
      t.integer :year
      t.integer :transaction_group
      t.text :description
      t.timestamps
    end
    add_index :cash_transactions, %i[month year]
  end
end
