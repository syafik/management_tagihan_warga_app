class CashFlow < ApplicationRecord

  before_save :set_total_cash

  def self.ransack_predicates
    [
        ["Equal", 'eq']
    ]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["year"]
  end

  private

  def set_total_cash
    self.total = self.cash_in - self.cash_out
  end

end
