# frozen_string_literal: true

# storing debt data

# == Schema Information
#
# Table name: debts
#
#  id          :bigint           not null, primary key
#  debt_date   :date
#  debt_type   :integer
#  description :text
#  value       :float
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer
#
class Debt < ApplicationRecord
  belongs_to :user

  TYPE = {
    'PINJAM' => 1,
    'BAYAR' => 2
  }.freeze

  def self.ransack_predicates
    [
      %w[Contains cont],
      ['Not Contains', 'not_cont'],
      %w[Equal eq],
      ['Not Equal', 'not_eq'],
      ['Less Than', 'lt'],
      ['Less Than or Equal to', 'lteq'],
      ['Greater Than', 'gt'],
      ['Greater Than or Equal to', 'gteq']
    ]
  end

  after_commit :create_cash_transaction, on: :create

  def create_cash_transaction
    p 'CREATE CASH TRANSACTION'
    case debt_type
    when 1
      CashTransaction.create(
        month: debt_date.month,
        year: debt_date.year,
        transaction_date: debt_date,
        transaction_type: CashTransaction::TYPE['KREDIT'],
        transaction_group: CashTransaction::GROUP['KASBON'],
        description: "#{user.name} Pinjam Uang",
        total: value,
        pic_id: User.where(role: 2).first.id
      )
    when 2
      CashTransaction.create(
        month: debt_date.month,
        year: debt_date.year,
        transaction_date: debt_date,
        transaction_type: CashTransaction::TYPE['DEBIT'],
        transaction_group: CashTransaction::GROUP['BAYAR KASBON'],
        description: "#{user.name} Bayar Cicilan Hutang",
        total: value,
        pic_id: User.where(role: 2).first.id
      )
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "debt_date", "debt_type", "description", "id", "updated_at", "user_id", "value"]
  end
end
