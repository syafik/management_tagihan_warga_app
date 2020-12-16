class AddKkToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :kk, :boolean, default: false
  end
end
