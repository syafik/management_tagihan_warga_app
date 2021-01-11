# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include DeviseTokenAuth::Concerns::SetUserByToken

      before_action :authenticate_user!

      before_action :configure_permitted_parameters, if: :devise_controller?

      protected

      def configure_permitted_parameters
        added_attrs = [:device_token, :device_type]
        devise_parameter_sanitizer.permit :sign_in, keys: added_attrs
      end
    end
  end
end
