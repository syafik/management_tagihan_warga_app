class AddFreeToAddresses < ActiveRecord::Migration[7.0]
  def change
    add_column :addresses, :free, :boolean, default: false
  end
end
