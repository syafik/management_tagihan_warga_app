# frozen_string_literal: true

class DebtsController < ApplicationController
  before_action :set_debt, only: %i[show edit update destroy]

  # GET /debts
  # GET /debts.json
  def index
    @q = Debt.ransack(params[:q])
    @q.sorts = 'id asc' if @q.sorts.empty?
    @debts = @q.result.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def search
    index
    respond_to do |format|
      format.html { redirect_to debts_path }
      format.js { render 'index.js.erb' }
    end
  end

  # GET /debts/1
  # GET /debts/1.json
  def show; end

  # GET /debts/new
  def new
    @debt = Debt.new
  end

  # GET /debts/1/edit
  def edit; end

  # POST /debts
  # POST /debts.json
  def create
    @debt = Debt.new(debt_params)

    respond_to do |format|
      if @debt.save
        format.html { redirect_to @debt, notice: 'Debt was successfully created.' }
        format.json { render :show, status: :created, location: @debt }
      else
        format.html { render :new }
        format.json { render json: @debt.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /debts/1
  # PATCH/PUT /debts/1.json
  def update
    respond_to do |format|
      if @debt.update(debt_params)
        format.html { redirect_to @debt, notice: 'Debt was successfully updated.' }
        format.json { render :show, status: :ok, location: @debt }
      else
        format.html { render :edit }
        format.json { render json: @debt.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /debts/1
  # DELETE /debts/1.json
  def destroy
    @debt.destroy
    respond_to do |format|
      format.html { redirect_to debts_url, notice: 'Debt was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_debt
    @debt = Debt.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def debt_params
    params.require(:debt).permit(:user_id, :value, :description, :debt_date, :debt_type)
  end
end
