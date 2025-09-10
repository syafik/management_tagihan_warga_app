class AddFinancialSettingsToAppSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :app_settings, :starting_balance, :decimal, precision: 15, scale: 2, default: 0
    add_column :app_settings, :starting_year, :integer, default: 2025
  end
end
