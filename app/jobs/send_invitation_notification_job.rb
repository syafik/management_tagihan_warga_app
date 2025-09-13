# frozen_string_literal: true

# Job to send WhatsApp invitation notification in the background
class SendInvitationNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, address_id)
    user = User.find(user_id)
    address = Address.find(address_id)
    
    Rails.logger.info "Sending invitation notification to #{user.phone_number} for address #{address.id}"
    
    whatsapp_service = WhatsappService.new
    message = build_invitation_message(user, address)
    result = whatsapp_service.send_login_code(user.phone_number, message)
    
    if result[:success]
      Rails.logger.info "Invitation notification sent successfully to #{user.phone_number}"
    else
      Rails.logger.error "Failed to send invitation notification to #{user.phone_number}: #{result[:message]}"
      Rails.logger.error "Error details: #{result[:error]}" if result[:error]
    end
    
    result
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "SendInvitationNotificationJob failed - record not found: #{e.message}"
    # Don't retry if record is not found
  rescue StandardError => e
    Rails.logger.error "SendInvitationNotificationJob failed for user #{user_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise for retry mechanism
  end

  private

  def build_invitation_message(user, address)
    <<~MESSAGE
      🏠 *Selamat! Anda telah diberi akses ke sistem manajemen Puri Ayana*
      
      📍 *Alamat:* #{address.full_address}
      👨‍👩‍👧‍👦 *Kepala Keluarga:* #{user.name || "Belum diset"}
      📱 *Nomor:* #{user.phone_number}
      🔐 *Akses aplikasi:* https://app.puriayana.com
      
      Gunakan nomor telepon Anda untuk masuk dengan kode verifikasi.
      
      Terima kasih! 🙏
      Selamat beraktifitas!
      Semoga Anda senantiasa sehat dan diberikan kemurahan rejeki. Aamiin 🤲
      
      Salam,
      Pengurus Puri Ayana
    MESSAGE
  end
end