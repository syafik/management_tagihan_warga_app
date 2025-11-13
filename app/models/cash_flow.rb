# frozen_string_literal: true

# storing cash flow data

# == Schema Information
#
# Table name: cash_flows
#
#  id         :bigint           not null, primary key
#  cash_in    :float
#  cash_out   :float
#  month      :integer
#  total      :float
#  year       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_cash_flows_on_month_and_year  (month,year)
#
class CashFlow < ApplicationRecord
  before_save :set_total_cash
  after_commit :create_cash_info, on: :create

  def self.ransack_predicates
    [
      %w[Equal eq]
    ]
  end

  def self.ransackable_attributes(_auth_object = nil)
    ['year']
  end

  def self.info(year)
    cf = CashFlow.where(year:year)
    {year: year, pemasukan: cf.sum(:cash_in), pengeluaran: cf.sum(:cash_out) }
  end

  def month_info
    UserContribution::MONTHNAMES.invert[month]
  end


  private

  def set_total_cash
    self.total = cash_in - cash_out
  end

  def create_cash_info
    cf = CashFlow.all.order('month DESC, year  DESC').first
    CashInfo.create(title: "Total Kas Sampai #{cf.month_info} #{cf.year}", remaining: CashFlow.sum(:cash_in) - CashFlow.sum(:cash_out))
  end
end
