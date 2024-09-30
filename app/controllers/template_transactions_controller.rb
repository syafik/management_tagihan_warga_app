class TemplateTransactionsController < ApplicationController
  def index
    @template_transactions = TemplateTransaction.page(params[:page])
  end

  def new
    @template_transaction = TemplateTransaction.new
  end
end
