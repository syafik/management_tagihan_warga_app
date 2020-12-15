# frozen_string_literal: true

class ChangeTransactionDateDataTypeInCashTransactions < ActiveRecord::Migration[5.2]
  def change
    change_column :cash_transactions, :transaction_date, :date
  end
end
