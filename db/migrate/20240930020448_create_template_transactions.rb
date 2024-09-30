class CreateTemplateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :template_transactions do |t|
      t.text :description
      t.integer :transaction_type
      t.integer :transaction_group
      t.float :amount
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
