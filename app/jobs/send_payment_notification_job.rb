# frozen_string_literal: true

# Job to send WhatsApp payment notification to head of family
class SendPaymentNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_contribution_id)
    user_contribution = UserContribution.find(user_contribution_id)
    address = user_contribution.address
    head_of_family = address.head_of_family

    # Skip if no head of family found
    return unless head_of_family

    Rails.logger.info "Sending payment notification to #{head_of_family.phone_number} for address #{address.block_address}"

    whatsapp_service = WhatsappService.new
    message = build_payment_message(user_contribution, address, head_of_family)
    result = whatsapp_service.send_login_code(head_of_family.phone_number, message)

    Rails.logger.info message

    if result[:success]
      Rails.logger.info "Payment notification sent successfully to #{head_of_family.phone_number}"
    else
      Rails.logger.error "Failed to send payment notification to #{head_of_family.phone_number}: #{result[:message]}"
      Rails.logger.error "Error details: #{result[:error]}" if result[:error]
    end

    result
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "SendPaymentNotificationJob failed - record not found: #{e.message}"
    # Don't retry if record is not found
  rescue StandardError => e
    Rails.logger.error "SendPaymentNotificationJob failed for user_contribution #{user_contribution_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise for retry mechanism
  end

  private

  def build_payment_message(user_contribution, address, head_of_family)
    payment_method = user_contribution.payment_type == 2 ? 'TRANSFER' : 'CASH'
    receiver_name = user_contribution.receiver&.name&.upcase || 'PETUGAS'
    amount = number_to_currency(user_contribution.contribution)
    date = user_contribution.pay_at.strftime('%d %B %Y')

    <<~MESSAGE
      ✅ *Konfirmasi Pembayaran Iuran*

      Yth. Bapak/Ibu *#{head_of_family.name}*

      Pembayaran iuran untuk:
      🏠 *Alamat:* #{address.block_address.upcase}
      💰 *Nominal:* #{amount}
      📅 *Tanggal:* #{date}
      💳 *Metode:* #{payment_method}
      👤 *Diterima oleh:* #{receiver_name}

      Terima kasih atas partisipasi Anda dalam menjaga lingkungan Puri Ayana.

      Untuk informasi lebih lanjut, silakan akses aplikasi di https://app.puriayana.com

      Salam,
      Pengurus Puri Ayana 🏡
    MESSAGE
  end

  def number_to_currency(amount)
    "Rp #{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
  end
end
