class AddExpoPushTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :expo_push_token, :string
  end
end
