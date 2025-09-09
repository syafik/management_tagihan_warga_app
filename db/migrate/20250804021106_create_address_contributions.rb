# frozen_string_literal: true

# Create address_contributions table for address-specific contribution rates
class CreateAddressContributions < ActiveRecord::Migration[7.0]
  def change
    create_table :address_contributions do |t|
      t.references :address, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :effective_from, null: false
      t.date :effective_until, null: true # null means indefinite
      t.text :reason # reason for the special rate
      t.boolean :active, default: true

      t.timestamps
    end

    # Add indexes
    add_index :address_contributions, [:address_id, :effective_from]
    add_index :address_contributions, :effective_from
    add_index :address_contributions, :active
    
    # Ensure no overlapping periods for same address
    add_index :address_contributions, [:address_id, :effective_from, :effective_until], 
              unique: true, name: 'index_address_contributions_on_period'
  end
end