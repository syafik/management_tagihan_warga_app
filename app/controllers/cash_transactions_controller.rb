# frozen_string_literal: true

class CashTransactionsController < ApplicationController
  def index
    current_year = Date.current.year
    current_month = Date.current.month

    # Set default year to current year if it's starting_year or later, otherwise starting_year
    @year_selected = params[:year_eq]&.to_i || [current_year, AppSetting.starting_year].max
    @pic_selected = params[:pic_id_eq].presence

    # Set default month to current month if we're in starting_year or later, otherwise January
    @month_selected = if @year_selected == current_year && current_year >= AppSetting.starting_year
                        params[:month_eq]&.to_i || current_month
                      else
                        params[:month_eq]&.to_i || 1
                      end
    selected_date = Date.parse("#{@year_selected}-#{@month_selected}-10")
    @cash_transactions = CashTransaction.where(transaction_date: selected_date.beginning_of_month..selected_date.end_of_month)
    @cash_transactions = @cash_transactions.where(pic_id: params[:pic_id_eq]) unless params[:pic_id_eq].blank?
    @cash_transactions = @cash_transactions.order('transaction_date ASC')
    @debit_total = @cash_transactions.select { |t| t.transaction_type == CashTransaction::TYPE['DEBIT'] }.sum(&:total)
    @credit_total = @cash_transactions.select { |t| t.transaction_type == CashTransaction::TYPE['KREDIT'] }.sum(&:total)
    @cash_closed = CashTransaction.closed?(@month_selected, @year_selected)
    respond_to do |format|
      format.html
    end
  end


  def new
    current_year = Date.current.year
    current_month = Date.current.month

    @year_selected = [current_year, AppSetting.starting_year].max
    @month_selected = @year_selected == current_year && current_year >= AppSetting.starting_year ? current_month : 1

    @ct = CashTransaction.new
  end

  def create
    @year_selected = params[:year]
    @month_selected = params[:month]
    @ct = CashTransaction.new(
      month: params[:month],
      year: params[:year],
      pic_id: params[:pic_id],
      total: params[:total].gsub(/[^\d]/, '').to_f,
      transaction_date: params[:transaction_date],
      transaction_type: params[:transaction_type],
      description: params[:description],
      transaction_group: params[:transaction_group]
    )
    if @ct.save
      redirect_to cash_transactions_path, notice: 'Create transaction success.'
    else
      render :new
    end
  end

  def import_data
    @year_selected = Date.current.year
    @month_selected = Date.current.month - 1
  end

  def do_import_data
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    source = params[:source].to_i
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[source]
    transaction_type = params[:transaction_type]
    (3..ws.num_rows).each do |row|
      tgl_transaksi = ws[row, 1].strip.blank? ? "#{params[:year]}-#{params[:month]}-11" : ws[row, 1].strip
      deskripsi = ws[row, 2]
      total = ws[row, 3]
      pic = ws[row, 4]
      next if total.blank? || deskripsi.blank?

      CashTransaction.create!(
        month: params[:month],
        year: params[:year],
        pic_id: pic.presence || '72', # pic syafik klo gak di set
        total: total.gsub(/[^\d]/, '').to_f,
        transaction_date: tgl_transaksi,
        transaction_type:,
        description: deskripsi,
        transaction_group: CashTransaction::GROUP['LAIN-LAIN']
      )
    end
    redirect_to cash_transactions_path, notice: 'Import data success'
  end

  def edit
    @ct = CashTransaction.find(params[:id])
    @month_selected = @ct.month
    @year_selected = @ct.year
  end

  def update
    @ct = CashTransaction.find(params[:id])
    if @ct.update_columns(
      month: params[:month],
      year: params[:year],
      pic_id: params[:pic_id],
      total: params[:total].gsub(/[^\d]/, '').to_f,
      transaction_date: params[:transaction_date],
      transaction_type: params[:transaction_type],
      description: params[:description],
      transaction_group: params[:transaction_group]
    )
      redirect_to cash_transactions_path, notice: 'Data updated.'
    else
      render edit_cash_transaction_path(@ct)
    end
  end

  def destroy
    @ct = CashTransaction.find(params[:id])
    @ct.destroy
    redirect_to cash_transactions_path, notice: 'Create transaction was successfully deleted.'
  end

  def close_transaction
    if CashFlow.where(year: params[:year], month: params[:month]).exists?
      redirect_to cash_transactions_path, alert: 'Already closed!'
    else
      selected_date = Date.parse("#{params[:year]}-#{params[:month]}-10")
      cash_transactions = CashTransaction.select('transaction_type, total, month, year').where(transaction_date: selected_date.beginning_of_month..selected_date.end_of_month)
      debit_total = cash_transactions.select { |t| t.transaction_type == CashTransaction::TYPE['DEBIT'] }.sum(&:total)
      credit_total = cash_transactions.select { |t| t.transaction_type == CashTransaction::TYPE['KREDIT'] }.sum(&:total)

      CashFlow.create(
        year: params[:year],
        month: params[:month],
        cash_in: debit_total,
        cash_out: credit_total,
        total: debit_total - credit_total
      )
      redirect_to cash_transactions_path,
                  alert: "Transaction #{params[:month]}, #{params[:year]} was successfully closed."
    end
  end

  def show_report
    @report_items = []
    @debit_total = 0
    @credit_total = 0
    selected_date = Date.parse("#{params[:year]}-#{params[:month]}-10")
    cash_transactions = CashTransaction.where(transaction_date: selected_date.beginning_of_month..selected_date.end_of_month).order('transaction_date ASC')
    CashTransaction::REPORT_WARGA.each do |key, value|
      if value.is_a?(Array)
        total = cash_transactions.select { |t| value.include?(t.transaction_group) }.sum(&:total)
        if key.include?('PEMASUKAN')
          @report_items << ['cash_in', '', key, total]
          @debit_total += total
        else
          @report_items << ['cash_out', '', key, total]
          @credit_total += total
        end
      else
        cash_transactions.select { |t| value == t.transaction_group }.each do |t|
          if key.include?('PEMASUKAN')
            @report_items << ['cash_in', t.transaction_date.strftime('%d %B %Y'), t.description, t.total]
            @debit_total += t.total
          else
            @report_items << ['cash_out', t.transaction_date.strftime('%d %B %Y'), t.description, t.total]
            @credit_total += t.total
          end
        end
      end
    end
    respond_to do |format|
      format.html
      format.pdf do
        html = render_to_string('transaction_report', layout: 'report', locals: { report_items: @report_items,
                                                                                  month: params[:month], year: params[:year],
                                                                                  debit_total: @debit_total, credit_total: @credit_total })
        kit = PDFKit.new(html)
        kit.stylesheets << "#{Rails.root}/app/assets/stylesheets/application.css"
        kit.stylesheets << "#{Rails.root}/app/assets/stylesheets/style.css"
        send_data(kit.to_pdf, filename: "laporan_transaksi_#{params[:month]}_#{params[:year]}.pdf",
                              type: 'application/pdf', disposition: 'inline')
      end
    end
  end
end
