class ChangePayAtDataTypeInUserContributions < ActiveRecord::Migration[5.2]
  def change
    change_column :user_contributions, :pay_at, :date
  end
end
