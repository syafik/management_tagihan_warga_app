# frozen_string_literal: true

module Api
  module V1
    class UserController < Api::V1::BaseController
      skip_before_action :authenticate_user!, only: %i[reset_password reset_password_token]

      def profile
        render json: { status: true, profile: current_user, address: current_user.address }, status: :ok
      end

      def reset_password_token
        check_user = User.where(email: params[:email]).first
        if check_user
          token = ('0'..'9').to_a.sample(5).join
          check_user.reset_password_token = token
          check_user.reset_password_sent_at = Time.current
          check_user.save
          check_user.deliver_reset_password_token_email(token)
          render status: 200,
                 json: { status: true, email: check_user.email,
                         message: 'Token untuk reset password sudah dikirim ke email anda, silakan cek email anda.' }
        else
          render status: 401,
                 json: { status: false, message: 'Maaf, Email yang dimasukkan tidak terdaftar dalam system.' }
        end
      end

      def reset_password
        check_user = User.where(email: params[:email]).first
        if check_user
          if check_user.reset_password_token != params[:token]
            return render status: 402,
                          json: { status: false,
                                  message: 'Token yang di masukkan salah, silakan periksa kembali token Anda.' }
          end
          if check_user.reset_password_sent_at + 5.minutes >= Time.current
            return render status: 402, json: { status: false, message: 'Token sudah kadaluarsa, silakan resend token' }
          end

          if params[:new_password] != params[:new_password_confirmation]
            return render status: 402,
                          json: { status: false,
                                  message: 'Konfirmasi password harus sama.' }
          end

          check_user.password = params[:new_password]
          if check_user.save
            render status: 200,
                   json: { status: true,
                           message: 'Password sudah terupdate dan sudah bisa di gunakan. Silakan login kembali.' }
          else
            render status: 402, json: { status: false, message: 'Reset password gagal.', error: check_user.errors }
          end
        else
          render status: 402,
                 json: { status: false, message: 'Maaf, Email yang dimasukkan tidak terdaftar dalam system.' }
        end
      end
    end
  end
end
