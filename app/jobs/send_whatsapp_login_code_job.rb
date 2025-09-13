# frozen_string_literal: true

# Job to send WhatsApp login code in the background
class SendWhatsappLoginCodeJob < ApplicationJob
  queue_as :default

  def perform(phone_number, login_code)
    Rails.logger.info "Sending WhatsApp login code #{login_code} to #{phone_number}"
    
    whatsapp_service = WhatsappService.new
    result = whatsapp_service.send_login_code(phone_number, login_code)
    
    if result[:success]
      Rails.logger.info "WhatsApp login code sent successfully to #{phone_number}"
    else
      Rails.logger.error "Failed to send WhatsApp login code to #{phone_number}: #{result[:message]}"
      Rails.logger.error "Error details: #{result[:error]}" if result[:error]
    end
    
    result
  rescue StandardError => e
    Rails.logger.error "SendWhatsappLoginCodeJob failed for #{phone_number}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise for retry mechanism
  end
end