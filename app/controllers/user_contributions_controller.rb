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
    @month_selected = Date.current.month - 1
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

    session = GoogleDrive::Session.from_service_account_key('config/gdrive_project.json')
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[params[:blok].to_i]
    (1..ws.num_rows).each do |row|
      block_address = ws[row, 2].strip
      contribution = ws[row, 3].strip
      arrear = ws[row, 4].strip
      bayar = ws[row, 5].strip
      tgl_bayar = ws[row, 6].strip
      next unless row >= 3

      address = Address.where(block_address: block_address).first
      next unless address

      1.upto(bayar.to_i) do |_i|
        UserContribution.create(
          month: params[:month],
          year: params[:year],
          address_id: address.id,
          contribution: contribution.gsub(/[^\d]/, '').to_f,
          receiver_id: params[:receiver_id],
          pay_at: (tgl_bayar.to_date || "#{params[:year]}-#{params[:month]}-20"),
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

  # GET /user_contributions/1
  # GET /user_contributions/1.json
  def show
    @address = @user_contribution.address
    @user_contributions = @address.user_contributions
  end

  # GET /user_contributions/new
  def new
    @user_contribution = UserContribution.new
  end

  # GET /user_contributions/1/edit
  def edit; end

  # POST /user_contributions
  # POST /user_contributions.json
  def create
    @user_contribution = UserContribution.new(user_contribution_params)
    @user_contribution.blok = @user_contribution.address.block_address.gsub(/[^A-Za-z]/,'') rescue ''
    respond_to do |format|
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
        format.html { redirect_to @user_contribution, notice: 'User contribution was successfully created.' }
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
    session = GoogleDrive::Session.from_service_account_key('config/gdrive_project.json')
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
            total_paid = UserContribution.where(address_id: address.id).count
            total_paid_should_be = (year.to_i - 2020) * 12 + month.to_i
            ws[row, 4] = total_paid_should_be - total_paid
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
end
