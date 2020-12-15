# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!, except: [:show_report], unless: -> { request.format.json? }
  before_action :action_allowed, only: %i[new create edit update], unless: lambda { |controller|
                                                                             controller.request.format.json?
                                                                           }
  protect_from_forgery with: :null_session, if: -> { request.format.json? }

  def action_allowed
    redirect_to '/', alert: 'Anda tidak bisa mengakses action yang di tuju.' if current_user && current_user.role != 2
  end

  def authenticate_current_user
    head :unauthorized if current_user_get.nil?
  end

  def current_user_get
    return nil unless cookies[:auth_headers]

    auth_headers = JSON.parse(cookies[:auth_headers])
    expiration_datetime = DateTime.strptime(auth_headers['expiry'], '%s')
    current_user = User.find_by(uid: auth_headers['uid'])

    if current_user&.tokens&.key?(auth_headers['client']) &&
       expiration_datetime > DateTime.now
      @current_user = current_user
    end

    @current_user
  end

  def verify_api
    params[:controller].split('/')[0] != 'devise_token_auth'
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[uid provider phone_number name])
  end
end
