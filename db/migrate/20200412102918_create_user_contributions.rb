# frozen_string_literal: true

class CreateUserContributions < ActiveRecord::Migration[5.2]
  def change
    create_table :user_contributions do |t|
      t.integer :user_id
      t.integer :year
      t.integer :month
      t.float :contribution
      t.datetime :pay_at
      t.integer :receiver_id
      t.integer :payment_type
      t.text :description

      t.timestamps
    end

    add_index :user_contributions, :user_id
    add_index :user_contributions, :year
    add_index :user_contributions, :month
  end
end
