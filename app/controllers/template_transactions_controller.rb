class TemplateTransactionsController < ApplicationController
  before_action :find_template_transaction, only: [ :show, :edit, :update, :destroy ]
  def index
    @template_transactions = TemplateTransaction.page(params[:page])
  end

  def new
    @template_transaction = TemplateTransaction.new
  end

  def create
    @template_transaction = TemplateTransaction.new(template_transaction_params)
    respond_to do |format|
      if @template_transaction.save
        format.html { redirect_to @template_transaction, notice: 'Template was successfully created.' }
        format.json { render :show, status: :created, location: @template_transaction }
      else
        format.html { render :new }
        format.json { render json: @template_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  def show; end

  def edit; end

  def update
    respond_to do |format|
      if @template_transaction.update(template_transaction_params)
        format.html { redirect_to @template_transaction, notice: 'Template was successfully updated.' }
        format.json { render :show, status: :created, location: @template_transaction }
      else
        format.html { render :new }
        format.json { render json: @template_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def find_template_transaction
    @template_transaction = TemplateTransaction.find(params[:id])
  end

  def template_transaction_params
    params.require(:template_transaction).permit(:description, :transaction_type, :transaction_group, :amount, :active)
  end
end
