class AddIndexOnTransactionDate < ActiveRecord::Migration[5.2]
  def change
    add_index :cash_transactions, :transaction_date
    add_index :user_contributions, :pay_at
  end
end
