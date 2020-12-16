# frozen_string_literal: true

module Api
  module V1
    class HomeController < Api::V1::BaseController
      def home_page
        render status: 200,  json: { 
          status: true, 
          tagihan: current_user.tagihan_now, 
          last_payment: current_user.last_payment_contribution, 
          blok: current_user.address ? current_user.address.block_address : "-",
          info: AppSetting.first.home_page_text % {user: current_user.name, greeting: Time.greeting_message_time },
          cash_flow: CashFlow.info((Date.current-1.month).month, (Date.current-1.month).year),
          last_5_transaction: {
            info: { month: UserContribution::MONTHNAMES.invert[Date.current.month], year: Date.current.year}, 
            transactions: CashTransaction.last_5_transaction
          }
        }
      end

      def cash_flows
        cash_flows = CashFlow.where(year: params[:year])
        render json: { status: true, cash_flows: cash_flows }, status: :ok
      end

      def contributions
        render json: { status: true, contributions: current_user.address.try(:user_contributions) }, status: :ok
      end

      def address_info
        address = Address.where(block_address: params[:block]).first
        if address
          render json: { status: true, address: address, users: address.users  }, status: :ok
        else
          render status: 404, json: {status: false, message: 'Address not found'}
        end
      end

    end
  end
end
