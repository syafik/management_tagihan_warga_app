# frozen_string_literal: true

# storing cash flow data

class CashFlow < ApplicationRecord
  before_save :set_total_cash

  def self.ransack_predicates
    [
      %w[Equal eq]
    ]
  end

  def self.ransackable_attributes(_auth_object = nil)
    ['year']
  end

  private

  def set_total_cash
    self.total = cash_in - cash_out
  end
end
