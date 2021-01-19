class CreateCashInfos < ActiveRecord::Migration[5.2]
  def change
    create_table :cash_infos do |t|
      t.string :title
      t.float :remaining
      t.timestamps
    end
    cf = CashFlow.all.order('month DESC, year  DESC').first
    CashInfo.create(title: "Total Sisa Kas per #{cf.month_info} #{cf.year}", remaining: CashFlow.sum(:cash_in) - CashFlow.sum(:cash_out))
  end
end
