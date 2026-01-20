# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    # before_action :configure_sign_in_params, only: [:create]

    layout 'user_authentication'

    # GET /resource/sign_in
    def new
      self.resource = resource_class.new(sign_in_params)
      clean_up_passwords(resource)
      yield resource if block_given?
      respond_with(resource, serialize_options(resource))
    end

    # POST /resource/sign_in
    def create
      # Check if this is a phone login request
      if params[:login_method] == 'password'
        handle_password_login_request
      elsif params[:phone_number].present?
        handle_phone_login_request
      else
        super
      end
    end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    protected

    def after_sign_out_path_for(_resource_or_scope)
      new_user_session_path
    end

    private

    def handle_phone_login_request
      phone_number = params[:phone_number]&.strip

      if phone_number.blank?
        flash.now[:error] = 'Silakan masukkan nomor telepon Anda'
        render :new and return
      end

      @user = User.find_by_phone(phone_number)

      if @user.nil?
        flash.now[:error] = 'Nomor telepon tidak ditemukan. Silakan hubungi administrator.'
        render :new and return
      end

      result = @user.send_login_code!

      if result[:success]
        session[:login_phone_number] = phone_number
        redirect_to verify_phone_login_path
      else
        flash.now[:error] = result[:message] || 'Gagal mengirimkan kode login. Silakan coba lagi.'
        render :new
      end
    end

    def handle_password_login_request
      phone_number = params[:phone_number]&.strip
      password = params[:password]

      if phone_number.blank? || password.blank?
        flash.now[:error] = 'Nomor WhatsApp dan password wajib diisi'
        render :new and return
      end

      @user = User.find_by_phone(phone_number)

      if @user.nil?
        flash.now[:error] = 'Nomor telepon tidak ditemukan. Silakan hubungi administrator.'
        render :new and return
      end

      if @user.valid_password?(password)
        sign_in(resource_name, @user)
        redirect_to after_sign_in_path_for(@user)
      else
        flash.now[:error] = 'Password salah. Silakan coba lagi.'
        render :new
      end
    end

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end
  end
end
