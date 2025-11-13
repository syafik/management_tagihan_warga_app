# frozen_string_literal: true

# == Schema Information
#
# Table name: installments
#
#  id               :bigint           not null, primary key
#  description      :text
#  paid_off         :boolean          default(FALSE)
#  transaction_type :integer
#  value            :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :integer
#
# Indexes
#
#  index_installments_on_parent_id  (parent_id)
#
class Installment < ApplicationRecord
  after_commit :create_cash_transaction, on: :create

  belongs_to :parent, class_name: 'Installment', foreign_key: 'parent_id', optional: true
  has_many :installment_transactions, class_name: 'Installment', foreign_key: 'parent_id'

  def total_paid
    installment_transactions.sum(&:value)
  end

  def remaining_installment
    value - total_paid
  end

  def paid_off?
    remaining_installment <= 0
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at description id paid_off parent_id transaction_type updated_at value]
  end

  private

  def create_cash_transaction
    if parent_id.nil?
      t_type = 1
      t_group = CashTransaction::GROUP['PEMASUKAN LAINNYA']
    else
      t_type = 2
      t_group = CashTransaction::GROUP['LAIN-LAIN']
    end
    CashTransaction.create(
      month: Date.current.month,
      year: Date.current.year,
      pic_id: User.where(role: 2).first.id,
      total: value,
      transaction_date: Date.current,
      transaction_type: t_type,
      description:,
      transaction_group: t_group
    )
  end
end
