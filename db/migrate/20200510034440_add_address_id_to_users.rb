# frozen_string_literal: true

class AddAddressIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :address_id, :integer
    add_index :users, :address_id
    remove_column :users, :block_address
    remove_column :users, :contribution
    remove_column :users, :arrears
  end
end
