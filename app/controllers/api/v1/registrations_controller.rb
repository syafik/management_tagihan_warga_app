# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < DeviseTokenAuth::RegistrationsController
      skip_before_action :verify_authenticity_token

      def sign_up_params
        params.require(:registration).permit(:email, :password, :name, :phone_number, :device_type, :device_token)
      end

      def render_create_success
        render json: {
          success: true,
          message: "Selamat, berhasil meembuat akun baru.",
          me: @resource,
          address: @resource.address,
          has_debt: current_user.has_debt?
        }
      end

    end
  end
end
