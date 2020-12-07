class CreateDebts < ActiveRecord::Migration[5.2]
  def change
    create_table :debts do |t|
      t.integer :user_id
      t.float :value
      t.text :description
      t.date :debt_date
      t.integer :debt_type

      t.timestamps
    end
  end
end
