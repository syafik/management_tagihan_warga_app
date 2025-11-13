# frozen_string_literal: true

# storing cash transaaction data

# == Schema Information
#
# Table name: cash_transactions
#
#  id                :bigint           not null, primary key
#  description       :text
#  month             :integer
#  total             :float
#  transaction_date  :date
#  transaction_group :integer
#  transaction_type  :integer
#  year              :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  pic_id            :integer
#
# Indexes
#
#  index_cash_transactions_on_month_and_year    (month,year)
#  index_cash_transactions_on_pic_id            (pic_id)
#  index_cash_transactions_on_transaction_date  (transaction_date)
#
class CashTransaction < ApplicationRecord
  validates :description, :total, :transaction_date, presence: true

  TYPE = {
    'DEBIT' => 1,
    'KREDIT' => 2
  }.freeze

  GROUP = {
    'IURAN WARGA' => 1,
    'GAJI DAN UPAH' => 2,
    'KASBON' => 3,
    'BAYAR KASBON' => 4,
    'LAIN-LAIN' => 5,
    'PEMASUKAN LAINNYA' => 6
  }.freeze

  TYPE_GROUP = {
    'DEBIT' => [1, 4, 6],
    'KREDIT' => [2, 3, 5]
  }.freeze

  REPORT_WARGA = {
    'PEMASUKAN IURAN WARGA' => [GROUP['IURAN WARGA'], GROUP['BAYAR KASBON']],
    'PEMASUKAN LAINNYA' => GROUP['PEMASUKAN LAINNYA'],
    'PENGELUARAN GAJI UPAH' => [GROUP['GAJI DAN UPAH'], GROUP['KASBON']],
    'PENGELUARAN LAINNYA' => GROUP['LAIN-LAIN']
  }.freeze

  belongs_to :pic, class_name: 'User'

  def self.closed?(month, year)
    CashFlow.where(month:, year:).exists?
  end

  def self.last_5_transaction
    where(month: Date.current.month, year: Date.current.year).order('transaction_date desc').map do |a|
      { tgl: a.transaction_date.strftime('%d %B %Y'), deskripsi: a.description,
        type: a.transaction_type == 2 ? 'OUT' : 'IN', nilai: a.total }
    end
  end
end
