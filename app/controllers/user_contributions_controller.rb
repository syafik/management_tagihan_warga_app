# frozen_string_literal: true

class UserContributionsController < ApplicationController
  before_action :set_user_contribution, only: %i[show edit update destroy]

  # GET /user_contributions
  # GET /user_contributions.json
  def index
    @year_selected = params[:year_eq] || Date.current.year
    conditions = params[:block_address_eq].blank? ? {} : { block_address: params[:block_address_eq] }
    @addresses = Address.where(conditions)
    conditions = { year: @year_selected }
    ActiveRecord::Associations::Preloader.new(records: @addresses, associations: :user_contributions,
                                              scope: UserContribution.where(conditions)).call
    respond_to do |format|
      format.html
      format.js
    end
  end

  def search
    @year_selected = params[:year_eq] || Date.current.year
    conditions = params[:block_address_eq].blank? ? {} : { block_address: params[:block_address_eq] }
    @addresses = Address.where(conditions)
    conditions = { year: @year_selected }
    ActiveRecord::Associations::Preloader.new(records: @addresses, associations: :user_contributions,
                                              scope: UserContribution.where(conditions)).call
    respond_to do |format|
      format.html { redirect_to admins_path }
      format.js { render 'index' }
    end
  end

  def import_data
    @year_selected = Date.current.year
    @month_selected = Date.current.month
  end

  def import_data_transfer
    @year_selected = Date.current.year
    @month_selected = Date.current.month
  end

  def do_import_data
    blok_name = Address::BLOK_NAME.invert[params[:blok].to_i]
    user = User.find(params[:receiver_id])
    unless user.pic_blok.split(',').map(&:strip).include?(blok_name)
      redirect_to import_data_user_contributions_path,
                  alert: "#{user.name} bukan merupakan PIC blok #{blok_name}." and return
    end
    if TotalContribution.where(month: params[:month], year: params[:year], blok: blok_name).exists?
      redirect_to import_data_user_contributions_path,
                  alert: "Month #{params[:month]}-#{params[:year]} sudah tergenerate." and return
    end

    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[params[:blok].to_i]
    (1..ws.num_rows).each do |row|
      block_address = ws[row, 2].strip
      contribution = ws[row, 3].strip
      bayar = ws[row, 5].strip
      tgl_bayar = ws[row, 6].strip
      months_paid = ws[row, 7].strip.split(",")
      next unless row >= 3

      address = Address.where(block_address: block_address).first
      next unless address

      year_selected = params[:year].to_i
      0.upto(bayar.to_i - 1) do |i|
        month_selected = months_paid[i].to_i
        month_before = i.zero? ? month_selected : months[i - 1].to_i
        year_selected = month_before == 12 && month_selected < month_before ? (year_selected + 1) : year_selected

        UserContribution.create(
          month: month_selected,
          year: year_selected,
          address_id: address.id,
          contribution: contribution.gsub(/[^\d]/, '').to_f,
          receiver_id: params[:receiver_id],
          pay_at: tgl_bayar.to_date,
          blok: blok_name,
          payment_type: 1
        )
      end
    end

    t_date = Date.parse("#{params[:year]}-#{params[:month]}-20")
    CashTransaction.create(
      month: params[:month],
      year: params[:year],
      transaction_date: params[:transaction_date],
      transaction_type: CashTransaction::TYPE['DEBIT'],
      transaction_group: CashTransaction::GROUP['IURAN WARGA'],
      description: "Pendapatan Iuran Warga Blok #{blok_name}",
      total: UserContribution.where(pay_at: t_date.beginning_of_month..t_date.end_of_month, blok: blok_name, receiver_id: user.id).sum(&:contribution),
      pic_id: user.id
    )
    redirect_to user_contributions_path, notice: 'Import data success'
  end

  def do_import_data_transfer
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[6]
    total_transfer_amount = 0
    (1..ws.num_rows).each do |row|
      block_address = ws[row, 1].strip
      bayar = ws[row, 2].strip
      contribution = ws[row, 3].strip
      tgl_bayar = ws[row, 4].strip
      bulan_bayar = ws[row, 5].strip
      months = bulan_bayar.split(',')
      amount = contribution.gsub(/[^\d]/, '').to_f

      address = Address.where(block_address: block_address.upcase).first
      next unless address

      year_selected = params[:year].to_i
      0.upto(bayar.to_i - 1) do |i|
        month_selected = months[i].to_i
        month_before = i.zero? ? month_selected : months[i - 1].to_i
        year_selected = month_before == 12 && month_selected < month_before ? (year_selected + 1) : year_selected
        UserContribution.create!(
          month: month_selected,
          year: year_selected,
          address_id: address.id,
          contribution: amount,
          receiver_id: params[:receiver_id],
          pay_at: tgl_bayar&.to_date.presence || "#{year_selected}-#{month_selected}-20",
          blok: block_address[0].upcase,
          payment_type: 2
        )
        total_transfer_amount += amount
      end
    end

    CashTransaction.create(
      month: params[:month],
      year: params[:year],
      transaction_date: params[:transaction_date],
      transaction_type: CashTransaction::TYPE['DEBIT'],
      transaction_group: CashTransaction::GROUP['IURAN WARGA'],
      description: "Pendapatan Iuran Warga Yang Transfer",
      total: total_transfer_amount,
      pic_id: params[:receiver_id]
    )
    redirect_to user_contributions_path, notice: 'Import data transfer success'
  end

  def import_arrears_x
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    0.upto(3) do |blok|
      ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[blok]
      (1..ws.num_rows).each do |row|
        block_address = ws[row, 2].strip
        arrear = ws[row, 4].strip
        next unless row >= 3

        address = Address.where(block_address: block_address).first
        next unless address

        address.update_column(:arrears, arrear)
      end
    end
  end

  # GET /user_contributions/1
  # GET /user_contributions/1.json
  def show
    @address = @user_contribution.address
    @user_contributions = @address.user_contributions
  end

  # GET /user_contributions/new
  def new
    @user_contribution = UserContribution.new
    @month_info = generate_month_info
  end

  # GET /user_contributions/1/edit
  def edit; end

  # POST /user_contributions
  # POST /user_contributions.json
  def create
    success = false
    UserContribution.transaction do
      params[:user_contribution_month].each do |value|
        month, month_text, year = value.split(",")
        address = Address.find_by(id: params[:user_contribution][:address_id])
        params[:user_contribution][:month] = month.to_i
        params[:user_contribution][:year] = year.to_i
        params[:user_contribution][:description] = "#{address.block_address} Pembayaran bulan #{month_text} #{year}"
        @user_contribution = UserContribution.new(user_contribution_params)
        @user_contribution.blok = @user_contribution.address.block_address.gsub(/[^A-Za-z]/,'') rescue ''
        if @user_contribution.save
          CashTransaction.create(
            month: @user_contribution.month,
            year: @user_contribution.year,
            transaction_date: @user_contribution.pay_at,
            transaction_type: CashTransaction::TYPE['DEBIT'],
            transaction_group: CashTransaction::GROUP['IURAN WARGA'],
            description: @user_contribution.description,
            total: @user_contribution.contribution,
            pic_id: @user_contribution.receiver_id
          )
        else
          raise ActiveRecord::Rollback
        end
      end
      success = true
    end
    respond_to do |format|
      if success
        format.html { redirect_to contribution_by_address_user_contribution_path(@user_contribution.address), notice: 'User contribution was successfully created.' }
        format.json { render :show, status: :created, location: @user_contribution }
      else
        format.html { render :new }
        format.json { render json: @user_contribution.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_contributions/1
  # PATCH/PUT /user_contributions/1.json
  def update
    respond_to do |format|
      if @user_contribution.update(user_contribution_params)
        format.html { redirect_to @user_contribution, notice: 'User contribution was successfully updated.' }
        format.json { render :show, status: :ok, location: @user_contribution }
      else
        format.html { render :edit }
        format.json { render json: @user_contribution.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_contributions/1
  # DELETE /user_contributions/1.json
  def destroy
    @user_contribution.destroy
    respond_to do |format|
      format.html { redirect_to user_contributions_url, notice: 'User contribution was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def generate_tagihan
    @year_selected = Date.current.year
    @month_selected = Date.current.month
  end

  def import_arrears
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    Address::BLOK_NAME.each do |_key, value|
      ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[value]
      (1..ws.num_rows).each do |row|
        if row == 1
          ws[row, 1] =
            "DAFTAR IURAN BULAN WARGA  #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}  BLOK #{Address::BLOK_NAME.invert[value]}"
        elsif row >= 3
          block_address = ws[row, 2].strip
          contribution = ws[row, 3].strip
          tagihan = ws[row, 4].strip
          bayar = ws[row, 5].strip
          address = Address.where(block_address: block_address).first
          if address
            total_paid_should_be = (year.to_i - 2024) * 12 + month.to_i
            ws[row, 4] = total_paid_should_be - total_paid
            ws[row, 5] = nil
            ws[row, 6] = nil
            ws[row, 7] = nil
          end
        end
      end
      ws.save
    end
  end

  def do_generate_data
    month = begin
      params[:month]
    rescue StandardError
      Date.current.month
    end
    year = begin
      params[:year]
    rescue StandardError
      Date.current.year
    end
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    Address::BLOK_NAME.each do |_key, value|
      ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[value]
      (1..ws.num_rows).each do |row|
        if row == 1
          ws[row, 1] =
            "DAFTAR IURAN BULAN WARGA  #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}  BLOK #{Address::BLOK_NAME.invert[value]}"
        elsif row >= 3
          block_address = ws[row, 2].strip
          contribution = ws[row, 3].strip
          tagihan = ws[row, 4].strip
          bayar = ws[row, 5].strip
          address = Address.where(block_address: block_address).first
          if address
            total_paid = UserContribution.where(address_id: address.id).where("year = 2024").count
            total_paid_should_be = (year.to_i - 2024) * 12 + month.to_i
            ws[row, 4] = address.arrears + (total_paid_should_be - total_paid)
            ws[row, 5] = nil
            ws[row, 6] = nil
            ws[row, 7] = nil
          end
        end
      end
      ws.save
    end

    # PENGELUARAN WORKSHEET
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[5]
    (1..ws.num_rows).each do |row|
      if row == 1
        ws[row, 1] =
          "LAPORAN TRANSAKSI PEMAKAIAN KAS BULAN #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}"
      elsif row >= 3
        ws[row, 1] = nil
        ws[row, 2] = nil
        ws[row, 3] = nil
      end
    end
    ws.save

    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[7]
    (1..ws.num_rows).each do |row|
      if row == 1
        ws[row, 1] =
          "SYAFIK - LAPORAN TRANSAKSI PEMAKAIAN KAS BULAN #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}"
      elsif row >= 3
        ws[row, 1] = nil
        ws[row, 2] = nil
        ws[row, 3] = nil
      end
    end
    ws.save

    # LIST TRANSFER WORKSHEET
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[6]
    (1..ws.num_rows).each do |row|
      if row == 1
        ws[row, 1] =
          "DAFTAR IURAN TRANSFER #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}"
      elsif row >= 3
        ws[row, 1] = nil
        ws[row, 2] = nil
        ws[row, 3] = nil
        ws[row, 4] = nil
        ws[row, 5] = nil
      end
    end
    ws.save

    respond_to do |format|
      format.html { redirect_to user_contributions_url, notice: 'Data tagihan was successfully generated.' }
      format.json { head :no_content }
    end
  end

  def contribution_by_address
    @address = Address.find(params[:id])
    @contributions = @address.user_contributions
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user_contribution
    @user_contribution = UserContribution.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def user_contribution_params
    params.require(:user_contribution).permit(:address_id, :year, :month, :contribution, :pay_at, :receiver_id, :payment_type, :blok,
                                              :description, :transaction_date, :imported_cash_transaction)
  end

  def generate_month_info
    current_date = Date.today - 4.month
    months_info = []

    15.times do
      months_info << { month: current_date.strftime('%_m'), month_text: current_date.strftime('%B'), year: current_date.year }
      current_date = current_date >> 1
    end

    return months_info
  end
end
