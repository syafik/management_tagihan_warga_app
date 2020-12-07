class AddBlokToUserContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :user_contributions, :blok, :string
    remove_index :user_contributions, :year
    remove_index :user_contributions, :month
    add_index    :user_contributions, [:year, :month]
    add_index    :user_contributions, :address_id
  end
end
