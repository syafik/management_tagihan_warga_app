# frozen_string_literal: true

# Create contributions table to manage contribution rates over time
class CreateContributions < ActiveRecord::Migration[7.0]
  def change
    create_table :contributions do |t|
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :effective_from, null: false
      t.string :block, limit: 1 # A, B, C, D, F or null for all blocks
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end

    # Add indexes
    add_index :contributions, %i[effective_from block]
    add_index :contributions, :active
    add_index :contributions, :block
  end
end