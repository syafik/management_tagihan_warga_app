class AddExecuteCashFlowToUserContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :user_contributions, :imported_cash_transaction, :boolean, default: false
  end
end
