class AddPicBlokToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :pic_blok, :string
  end
end
