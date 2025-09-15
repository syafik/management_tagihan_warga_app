# frozen_string_literal: true

class InstallmentsController < ApplicationController
  before_action :set_installment, only: %i[show edit update destroy]

  # GET /installments
  # GET /installments.json
  def index
    @q = Installment.ransack(params[:q])
    @q.sorts = 'id asc' if @q.sorts.empty?
    @pagy, @installments = pagy(@q.result.includes(:installment_transactions).where('parent_id IS NULL'), items: 20)
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

  # GET /installments/1
  # GET /installments/1.json
  def show; end

  # GET /installments/new
  def new
    @installment = Installment.new
  end

  # GET /installments/1/edit
  def edit; end

  # POST /installments
  # POST /installments.json
  def create
    @installment = Installment.new(installment_params)

    respond_to do |format|
      if @installment.save
        format.html { redirect_to @installment, notice: 'Installment was successfully created.' }
        format.json { render :show, status: :created, location: @installment }
      else
        format.html { render :new }
        format.json { render json: @installment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /installments/1
  # PATCH/PUT /installments/1.json
  def update
    respond_to do |format|
      if @installment.update(installment_params)
        format.html { redirect_to @installment, notice: 'Installment was successfully updated.' }
        format.json { render :show, status: :ok, location: @installment }
      else
        format.html { render :edit }
        format.json { render json: @installment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /installments/1
  # DELETE /installments/1.json
  def destroy
    @installment.destroy
    respond_to do |format|
      format.html { redirect_to installments_url, notice: 'Installment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_installment
    @installment = Installment.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def installment_params
    params.require(:installment).permit(:description, :value, :parent_id)
  end
end
