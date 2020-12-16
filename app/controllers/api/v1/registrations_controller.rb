# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < DeviseTokenAuth::RegistrationsController
      skip_before_action :verify_authenticity_token

      def sign_up_params
        params.require(:registration).permit(:email, :password, :name, :phone_number)
      end
      
    end
  end
end
