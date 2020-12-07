class ReportPdf
 
  def initialize(report_items, month, year, debit, credit)
    @report_items = report_items
    @month = month
    @year = year
    @debit = debit
    @credit = credit
  end
 
  def to_pdf
    kit = PDFKit.new(as_html, page_size: 'A4')
    kit.to_file("#{Rails.root}/public/report.pdf")
  end
 
  def filename
    "laporan_transaksi_#{month}_#{year}.pdf"
  end
 
  private
 
    attr_reader :report_items, :month, :year, :debit, :credit
 
    def as_html
      render template: "cash_transactions/show_report", layout: "report", locals: { report_items: report_items, month: month, year: year, debit_total: debit, credit_total: credit }
    end
end