# frozen_string_literal: true

# Job to send individual payment reminder notification via WhatsApp
class SendPaymentReminderNotificationJob < ApplicationJob
  queue_as :default

  def perform(address_id, year, month)
    address = Address.find(address_id)
    head_of_family = address.head_of_family

    # Skip if no head of family found
    return unless head_of_family

    Rails.logger.info "Sending payment reminder to #{head_of_family.phone_number} for #{address.block_address}"

    whatsapp_service = WhatsappService.new
    message = build_reminder_message(address, head_of_family, year, month)
    result = whatsapp_service.send_message(head_of_family.phone_number, message)

    Rails.logger.info message

    if result[:success]
      Rails.logger.info "Payment reminder sent successfully to #{head_of_family.phone_number}"
    else
      Rails.logger.error "Failed to send payment reminder to #{head_of_family.phone_number}: #{result[:message]}"
      Rails.logger.error "Error details: #{result[:error]}" if result[:error]
    end

    result
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "SendPaymentReminderNotificationJob failed - record not found: #{e.message}"
    # Don't retry if record is not found
  rescue StandardError => e
    Rails.logger.error "SendPaymentReminderNotificationJob failed for address #{address_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise for retry mechanism
  end

  private

  def build_reminder_message(address, head_of_family, year, month)
    month_name = Date::MONTHNAMES[month]
    contribution_rate = address.current_contribution_rate || 150_000
    amount = number_to_currency(contribution_rate)

    # Calculate total arrears
    start_date = Date.new(2025, 1, 1)
    current_date = Date.new(year, month, 20) # Reminder date
    months_should_pay = ((current_date.year - start_date.year) * 12) + (current_date.month - start_date.month) + 1

    total_paid_2025 = address.user_contributions
                             .where('pay_at >= ? AND pay_at <= ?', start_date, current_date.end_of_month)
                             .count
    initial_arrears = address.arrears || 0
    total_arrears = months_should_pay - total_paid_2025 + initial_arrears

    <<~MESSAGE
      🔔 *Pengingat Pembayaran Iuran*

      Yth. Bapak/Ibu *#{head_of_family.name}*

      Kami ingin mengingatkan bahwa pembayaran iuran bulan *#{month_name} #{year}* belum kami terima.

      📍 *Alamat:* #{address.block_address.upcase}
      💰 *Nominal:* #{amount}/bulan
      📅 *Bulan:* #{month_name} #{year}
      #{total_arrears > 1 ? "⚠️ *Total Tunggakan:* #{total_arrears} bulan" : ''}

      *Cara Pembayaran:*
      💵 Transfer ke rekening resmi (lihat aplikasi)
      💵 Bayar tunai ke petugas keamanan

      Untuk informasi lebih lanjut atau konfirmasi pembayaran, silakan hubungi pengurus atau akses aplikasi di https://app.puriayana.com

      Terima kasih atas perhatian dan kerjasamanya dalam menjaga lingkungan Puri Ayana tetap nyaman.

      Salam,
      Pengurus Puri Ayana 🏡
    MESSAGE
  end

  def number_to_currency(amount)
    "Rp #{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
  end
end
