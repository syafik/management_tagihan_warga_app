# frozen_string_literal: true

class CreateUserDebts < ActiveRecord::Migration[5.2]
  def change
    create_table :user_debts do |t|
      t.integer :user_id
      t.float :owed
      t.float :paid
      t.boolean :paid_off, default: false
      t.timestamps
    end
    add_index :user_debts, :user_id
  end
end
