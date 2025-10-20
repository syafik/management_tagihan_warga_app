class AddSecuritySettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :allow_manage_transfer, :boolean, default: true
    add_column :users, :allow_manage_expense, :boolean, default: true
  end
end
