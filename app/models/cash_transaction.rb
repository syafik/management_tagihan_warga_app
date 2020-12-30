# frozen_string_literal: true

# storing cash transaaction data

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

  REPORT_WARGA = {
    'PEMASUKAN IURAN WARGA' => [GROUP['IURAN WARGA'], GROUP['BAYAR KASBON']],
    'PEMASUKAN LAINNYA' => GROUP['PEMASUKAN LAINNYA'],
    'PENGELUARAN GAJI UPAH' => [GROUP['GAJI DAN UPAH'], GROUP['KASBON']],
    'PENGELUARAN LAINNYA' => GROUP['LAIN-LAIN']
  }.freeze

  belongs_to :pic, class_name: 'User'

  def self.closed?(month, year)
    CashFlow.where(month: month, year: year).exists?
  end

  def self.last_5_transaction
    where(month: Date.current.month, year: Date.current.year).order("transaction_date desc").map{|a|
      {tgl: a.transaction_date.strftime("%d %B %Y"), deskripsi: a.description, type: a.transaction_type == 2 ? "OUT" : "IN", nilai: a.total}
    }
  end

end
