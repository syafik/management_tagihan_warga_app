class Api::V1::HomeController < Api::V1::BaseController

  before_action :authenticate_user!
  

  def profile
    render json: {status: true, profile: current_user}, status: :ok
  end

  def cash_flows
    cash_flows = CashFlow.where(year: params[:year])
    render json: {status: true, cash_flows: cash_flows}, status: :ok
  end

  def contributions
    render json: {status: true, contributions: current_user.address.try(:user_contributions)}, status: :ok
    
  end


end