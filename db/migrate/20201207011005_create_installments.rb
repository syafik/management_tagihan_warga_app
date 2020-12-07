class CreateInstallments < ActiveRecord::Migration[5.2]
  def change
    create_table :installments, force: true do |t|
      t.text :description
      t.float :value
      t.integer :transaction_type
      t.integer :parent_id
      t.timestamps
    end
    add_index :installments, :parent_id
  end
end
