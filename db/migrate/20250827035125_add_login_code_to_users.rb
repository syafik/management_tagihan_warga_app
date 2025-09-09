class AddLoginCodeToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :login_code, :string
    add_column :users, :login_code_expires_at, :datetime
  end
end
