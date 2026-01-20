# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    layout 'user_authentication'

    def create
      phone_number = params[:phone_number]&.strip

      if phone_number.blank?
        flash.now[:error] = 'Nomor WhatsApp wajib diisi'
        self.resource = resource_class.new
        render :new and return
      end

      self.resource = resource_class.find_by_phone(phone_number)

      if resource.nil?
        flash.now[:error] = 'Nomor WhatsApp tidak ditemukan. Silakan hubungi administrator.'
        self.resource = resource_class.new
        render :new and return
      end

      token = resource.send(:set_reset_password_token)
      reset_link = "#{request.base_url}#{edit_user_password_path(reset_password_token: token)}"
      Rails.logger.info "Reset password link for #{resource.phone_number}: #{reset_link}"

      result = WhatsappService.new.send_reset_password_link(resource.phone_number, reset_link)

      if result[:success]
        redirect_to new_user_password_path, notice: 'Link reset password sudah dikirim ke WhatsApp Anda.'
      else
        flash.now[:error] = result[:message] || 'Gagal mengirim link reset password. Silakan coba lagi.'
        render :new
      end
    end

    def update
      self.resource = resource_class.reset_password_by_token(resource_params)

      if resource.errors.empty?
        set_flash_message!(:notice, :updated)
        redirect_to new_user_session_path
      else
        flash.now[:error] = resource.errors.full_messages.to_sentence
        respond_with resource
      end
    end
    # GET /resource/password/new
    # def new
    #   super
    # end

    # POST /resource/password
    # def create
    #   super
    # end

    # GET /resource/password/edit?reset_password_token=abcdef
    # def edit
    #   super
    # end

    # PUT /resource/password
    # def update
    #   super
    # end

    # protected

    # def after_resetting_password_path_for(resource)
    #   super(resource)
    # end

    # The path used after sending reset password instructions
    # def after_sending_reset_password_instructions_path_for(resource_name)
    #   super(resource_name)
    # end
  end
end
