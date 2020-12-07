class AddPaidOffToInstallments < ActiveRecord::Migration[5.2]
  def change
    add_column :installments, :paid_off, :boolean, default: false
  end
end
