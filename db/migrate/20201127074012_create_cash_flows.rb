class CreateCashFlows < ActiveRecord::Migration[5.2]
  def change
    create_table :cash_flows do |t|
      t.float :cash_in
      t.float :cash_out
      t.float :total
      t.integer :month
      t.integer :year
      t.timestamps
    end
    add_index :cash_flows, [:month, :year]
  end
end
