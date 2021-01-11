class AddDeviceTypeDeviceTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :device_type, :string
    add_column :users, :device_token, :string
  end
end
