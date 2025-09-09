# frozen_string_literal: true

class AddressesController < ApplicationController
  before_action :set_address, only: %i[show edit update destroy pay_arrears]

  # GET /users
  # GET /users.json
  def index
    @q = Address.ransack(params[:q])
    @q.sorts = 'id asc' if @q.sorts.empty?
    @pagy, @addresses = pagy(@q.result)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def search
    index
    respond_to do |format|
      format.html { redirect_to addresses_path }
      format.js { render 'index.js.erb' }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show; end

  # GET /users/new
  def new
    @address = Address.new
  end

  # GET /users/1/edit
  def edit; end

  # POST /addresses/:id/pay_arrears
  def pay_arrears
    months_paid = params[:months_paid].to_i
    rate_per_month = params[:rate_per_month].to_i
    total_amount = params[:total_amount].to_i
    payment_date = Date.parse(params[:payment_date])

    # Get expected rate for 2024 (since arrears are from 2024 and below)
    expected_rate_2024 = @address.expected_contribution_for(12, 2024)

    # Validation
    if months_paid <= 0 || months_paid > @address.arrears
      redirect_to edit_address_path(@address), alert: 'Jumlah bulan yang dibayar tidak valid.' and return
    end

    if total_amount != (months_paid * rate_per_month)
      redirect_to edit_address_path(@address), alert: 'Total pembayaran tidak sesuai dengan perhitungan.' and return
    end

    # Validate that the rate used is correct for 2024
    if rate_per_month != expected_rate_2024
      redirect_to edit_address_path(@address),
                  alert: 'Tarif per bulan tidak sesuai dengan tarif yang berlaku di tahun 2024.' and return
    end

    Address.transaction do
      # Create cash transaction for arrears payment
      CashTransaction.create!(
        month: payment_date.month,
        year: payment_date.year,
        transaction_date: payment_date,
        transaction_type: CashTransaction::TYPE['DEBIT'],
        transaction_group: CashTransaction::GROUP['IURAN WARGA'],
        description: "#{@address.block_address} pembayaran tunggakan #{months_paid} bulan (tarif 2024: Rp#{format_currency(rate_per_month)})",
        total: total_amount,
        pic_id: current_user.id
      )

      # Reduce arrears
      new_arrears = [@address.arrears - months_paid, 0].max
      @address.update!(arrears: new_arrears)
    end

    redirect_to edit_address_path(@address),
                notice: "Pembayaran tunggakan #{months_paid} bulan berhasil diproses. Total: Rp#{format_currency(total_amount)} (Tarif 2024)"
  rescue StandardError => e
    redirect_to edit_address_path(@address), alert: "Terjadi kesalahan: #{e.message}"
  end

  # POST /users
  # POST /users.json
  def create
    @address = Address.new(address_params)

    respond_to do |format|
      if @address.save
        format.html { redirect_to @address, notice: 'Address was successfully created.' }
        format.json { render :show, status: :created, location: @address }
      else
        format.html { render :new }
        format.json { render json: @address.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @address.update(address_params)
        format.html { redirect_to @address, notice: 'Address was successfully updated.' }
        format.json { render :show, status: :ok, location: @address }
      else
        format.html { render :edit }
        format.json { render json: @address.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  # def destroy
  #   @Address.destroy
  #   respond_to do |format|
  #     format.html { redirect_to users_url, notice: 'Address was successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_address
    @address = Address.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def address_params
    params.fetch(:address, {}).permit(:block_address, :arrears, :free)
  end

  def format_currency(amount)
    return '0' if amount.nil? || amount.zero?

    # Format with Indonesian locale (using period as thousands separator)
    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  end
end
