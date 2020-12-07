class CashTransaction < ApplicationRecord

  validates :description, :total, :transaction_date, presence: true
  TYPE = {
    "DEBIT" => 1,
    "KREDIT" => 2
  }

  GROUP = {
    "IURAN WARGA" => 1,
    "GAJI DAN UPAH" => 2,
    "KASBON" => 3,
    "BAYAR KASBON" => 4,
    "LAIN-LAIN" => 5,
    "PEMASUKAN LAINNYA" => 6
  }

  REPORT_WARGA = {
    "PEMASUKAN IURAN WARGA" => [GROUP["IURAN WARGA"], GROUP["BAYAR KASBON"] , GROUP["PEMASUKAN LAINNYA"]],
    "PENGELUARAN GAJI UPAH" =>  [GROUP["GAJI DAN UPAH"], GROUP["KASBON"]],
    "PENGELUARAN LAINNYA" => GROUP["LAIN-LAIN"]
  }

  belongs_to :pic, class_name: "User"

  def self.closed?(month, year)
    CashFlow.where(month: month, year: year).exists?
  end
  
end
