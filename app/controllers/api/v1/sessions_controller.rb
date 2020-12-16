# frozen_string_literal: true

module Api
  module V1
    class SessionsController < DeviseTokenAuth::SessionsController
      skip_before_action :verify_authenticity_token, only: :create, raise: false

      def render_create_success
        render json: {
          success: true,
          message: "Login berhasil.",
          me: @resource,
          avatar: (url_for(@resource.avatar) rescue nil),
          address: @resource.address
        }
      end
    end
  end
end
