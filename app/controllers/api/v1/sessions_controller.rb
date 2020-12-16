# frozen_string_literal: true

module Api
  module V1
    class SessionsController < DeviseTokenAuth::SessionsController
      skip_before_action :verify_authenticity_token, only: :create, raise: false

      def render_create_success
        render status: 200, json: {
          success: true,
          message: "Login berhasil.",
          me: @resource,
          avatar: (url_for(@resource.avatar) rescue nil),
          address: @resource.address
        }
      end

      def render_new_error
       render status: 401, json: {
         success: false,
         message: 'Login gagal.'
       }
      end

      def render_create_error_bad_credentials
        render status: 401, json: {
          success: false,
          message: 'Password atau email yang dimasukkan salah.'
        }
      end

    end
  end
end
