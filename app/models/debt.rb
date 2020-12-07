class Debt < ApplicationRecord

  belongs_to :user

  TYPE = {
    "PINJAM" => 1,
    "BAYAR" => 2
  }

  def self.ransack_predicates
    [
        ["Contains", 'cont'],
        ["Not Contains", 'not_cont'],
        ["Equal", 'eq'],
        ["Not Equal", 'not_eq'],
        ["Less Than", 'lt'],
        ["Less Than or Equal to", 'lteq'],
        ["Greater Than", 'gt'],
        ["Greater Than or Equal to", 'gteq']
    ]
  end

  after_commit :create_cash_transaction, on: :create

  def create_cash_transaction
    p "CREATE CASH TRANSACTION"
    if self.debt_type == 1
      CashTransaction.create(
        month: self.debt_date.month,
        year: self.debt_date.year,
        transaction_date: self.debt_date,
        transaction_type: CashTransaction::TYPE["KREDIT"], 
        transaction_group: CashTransaction::GROUP["KASBON"], 
        description: "#{self.user.name} Pinjam Uang",
        total: self.value,
        pic_id: User.where(:role => 2).first.id
      )
    elsif self.debt_type == 2
      CashTransaction.create(
        month: self.debt_date.month,
        year: self.debt_date.year,
        transaction_date: self.debt_date,
        transaction_type: CashTransaction::TYPE["DEBIT"], 
        transaction_group: CashTransaction::GROUP["BAYAR KASBON"], 
        description: "#{self.user.name} Bayar Cicilan Hutang",
        total: self.value,
        pic_id: User.where(:role => 2).first.id
      )
    end
  end


end
