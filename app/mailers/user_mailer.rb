class UserMailer < ApplicationMailer

  def reset_password_email
    @user = params[:user]
    @new_password = params[:new_password]
    mail(to: @user.email, subject: "[Puri Ayana App] - Ini password baru anda!")
  end

  def reset_password_token_email
    @user = params[:user]
    @token = params[:token]
    mail(to: @user.email, subject: "[Puri Ayana App] - Ini reset password token anda!")
  end

end
