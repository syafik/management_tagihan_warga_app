class PhoneLoginsController < ApplicationController
  layout 'user_authentication'

  skip_before_action :authenticate_user!
  before_action :redirect_if_authenticated

  # Step 3: Show login code verification form
  def verify
    redirect_to new_user_session_path if session[:login_phone_number].blank?
  end

  # Step 4: Verify login code and authenticate
  def authenticate
    phone_number = session[:login_phone_number]
    login_code = params[:login_code]&.strip

    redirect_to new_user_session_path and return if phone_number.blank?

    if login_code.blank?
      flash.now[:error] = 'Silakan masukkan kode login'
      render :verify and return
    end

    @user = User.find_by_phone(phone_number)

    if @user.nil?
      session.delete(:login_phone_number)
      redirect_to new_user_session_path and return
    end

    if @user.login_code_valid?(login_code)
      # Login successful
      @user.clear_login_code!
      session.delete(:login_phone_number)
      sign_in(@user, remember: true)

      flash[:success] = 'Login berhasil!'
      redirect_to root_path
    else
      flash.now[:error] = if @user.login_code_expired?
                            'Kode login telah kedaluwarsa. Silakan minta kode baru.'
                          else
                            'Kode login tidak valid. Silakan periksa dan coba lagi.'
                          end
      render :verify
    end
  end

  # Resend login code
  def resend
    phone_number = session[:login_phone_number]

    redirect_to new_user_session_path and return if phone_number.blank?

    @user = User.find_by_phone(phone_number)

    if @user.nil?
      session.delete(:login_phone_number)
      redirect_to new_user_session_path and return
    end

    result = @user.send_login_code!

    if result[:success]
      flash[:success] = 'Kode login baru telah dikirim ke WhatsApp Anda!'
    else
      flash[:error] = result[:message] || 'Gagal mengirimkan kode login. Silakan coba lagi.'
    end

    redirect_to verify_phone_login_path
  end

  private

  def redirect_if_authenticated
    redirect_to root_path if user_signed_in?
  end
end
