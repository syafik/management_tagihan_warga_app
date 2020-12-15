# frozen_string_literal: true

class Installment < ApplicationRecord
  after_commit :create_cash_transaction, on: :create

  belongs_to :parent, class_name: 'Installment', foreign_key: 'parent_id', optional: true
  has_many :installment_transactions, class_name: 'Installment', foreign_key: 'parent_id'

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
      description: description,
      transaction_group: t_group
    )
  end
end
