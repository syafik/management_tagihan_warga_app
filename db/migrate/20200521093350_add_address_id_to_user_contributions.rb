class AddAddressIdToUserContributions < ActiveRecord::Migration[5.2]
  def change
    remove_column :user_contributions, :user_id
    add_column :user_contributions, :address_id, :integer
  end
end
