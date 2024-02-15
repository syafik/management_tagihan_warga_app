# frozen_string_literal: true

class CashFlowsController < ApplicationController
  before_action :set_cash_flow, only: %i[show edit update destroy]

  # GET /users
  # GET /users.json
  def index
    @q = CashFlow.ransack(params[:q])
    @cash_flows = @q.result.order('month, year asc')

    @total_cash_in = @cash_flows.sum(&:cash_in)
    @total_cash_out = @cash_flows.sum(&:cash_out)
    @grand_total = @cash_flows.sum(&:total)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def search
    index
    respond_to do |format|
      format.html { redirect_to cash_flows_path }
      format.js
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show; end

  # GET /users/new
  def new
    @cash_flow = CashFlow.new
  end

  # GET /users/1/edit
  def edit; end

  # POST /users
  # POST /users.json
  def create
    @cash_flow = CashFlow.new(cash_flow_params)

    respond_to do |format|
      if @cash_flow.save
        format.html { redirect_to @cash_flow, notice: 'CashFlow was successfully created.' }
        format.json { render :show, status: :created, location: @address }
      else
        format.html { render :new }
        format.json { render json: @cash_flow.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @cash_flow.update(cash_flow_params)
        format.html { redirect_to @cash_flow, notice: 'CashFlow was successfully updated.' }
        format.json { render :show, status: :ok, location: @cash_flow }
      else
        format.html { render :edit }
        format.json { render json: @cash_flow.errors, status: :unprocessable_entity }
      end
    end
  end

  def generate_report
    year = params[:year] || Date.current.year
    cash_flows = CashFlow.where(year: year).order('month, year asc')
    debit_total = cash_flows.sum(&:cash_in)
    credit_total = cash_flows.sum(&:cash_out)
    grand_total = cash_flows.sum(&:total)
    respond_to do |format|
      format.html
      format.pdf do
        html = render_to_string('transaction_report.html.erb', layout: 'report', locals: { cash_flows: cash_flows,
                                                                                            year: year, debit_total: debit_total, credit_total: credit_total, grand_total: grand_total })
        kit = PDFKit.new(html)
        kit.stylesheets << "#{Rails.root}/app/assets/stylesheets/application.css"
        kit.stylesheets << "#{Rails.root}/app/assets/stylesheets/style.css"
        send_data(kit.to_pdf, filename: "laporan_alur_kas_tahun_#{params[:year]}.pdf",
                              type: 'application/pdf', disposition: 'inline')
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
  def set_cash_flow
    @cash_flow = CashFlow.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def cash_flow_params
    params.fetch(:cash_flow, {}).permit(:month, :year, :cash_in, :cash_out, :total)
  end
end
