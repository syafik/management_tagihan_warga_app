class RemoveAddressFieldsFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :address_id, :integer
    remove_column :users, :kk, :boolean
  end
end
