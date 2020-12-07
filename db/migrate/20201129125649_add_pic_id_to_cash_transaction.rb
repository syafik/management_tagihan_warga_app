class AddPicIdToCashTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :cash_transactions, :pic_id, :integer
    add_index :cash_transactions, :pic_id
  end
end
