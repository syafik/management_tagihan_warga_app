# frozen_string_literal: true

# Job to send WhatsApp payment notification to head of family
# Supports both single and multiple contributions
class SendPaymentNotificationJob < ApplicationJob
  queue_as :default

  # Can accept:
  # - Single ID: perform(123) → send for 1 contribution
  # - Array of IDs: perform([123, 124, 125]) → send bulk message for multiple contributions
  # - With payment details: perform([123, 124], payment_id, arrears_count, total_amount, address_id)
  def perform(user_contribution_ids, payment_id = nil, arrears_count = 0, total_amount = nil, address_id = nil)
    user_contribution_ids = Array(user_contribution_ids)

    # Debug logging
    puts "=== SendPaymentNotificationJob START ==="
    puts "user_contribution_ids: #{user_contribution_ids.inspect}"
    puts "payment_id: #{payment_id.inspect}"
    puts "arrears_count: #{arrears_count.inspect}"
    puts "total_amount: #{total_amount.inspect}"
    puts "address_id: #{address_id.inspect}"

    # Get contributions
    contributions = UserContribution.where(id: user_contribution_ids).includes(:address, :receiver)
    puts "contributions found: #{contributions.count}"

    # Get payment if payment_id provided
    payment = Payment.find_by(id: payment_id) if payment_id.present?

    # Get address and head of family
    if payment.present?
      address = payment.address
      head_of_family = address&.head_of_family
    elsif contributions.any?
      address = contributions.first.address
      head_of_family = address.head_of_family
    elsif address_id.present?
      # Arrears-only payment
      address = Address.find_by(id: address_id)
      head_of_family = address&.head_of_family
    else
      return # No contributions, payment, or address
    end

    puts "address found: #{address&.block_address}"
    puts "head_of_family: #{head_of_family&.name}"

    # Skip if no head of family found
    return unless head_of_family && address

    # Skip if nothing to notify
    return if contributions.empty? && arrears_count.to_i == 0

    whatsapp_service = WhatsappService.new

    # Build universal message
    Rails.logger.info "Sending payment notification to #{head_of_family.phone_number}: #{contributions.size} contributions + #{arrears_count} arrears"
    message = build_payment_message(contributions, address, head_of_family, payment, arrears_count, total_amount)

    # Log message before sending (to both stdout and log file)
    log_message = <<~LOG
      #{'=' * 80}
      Sending WhatsApp notification to #{head_of_family.phone_number}
      Message content:
      #{message}
      #{'=' * 80}
    LOG

    puts log_message
    Rails.logger.info log_message

    result = whatsapp_service.send_message(head_of_family.phone_number, message)

    if result[:success]
      success_msg = "✅ Payment notification sent successfully to #{head_of_family.phone_number}"
      puts success_msg
      Rails.logger.info success_msg
    else
      error_msg = "❌ Failed to send payment notification to #{head_of_family.phone_number}: #{result[:message]}"
      error_detail = "Error details: #{result[:error]}" if result[:error]

      puts error_msg
      puts error_detail if error_detail
      Rails.logger.error error_msg
      Rails.logger.error error_detail if error_detail
    end

    result
  rescue ActiveRecord::RecordNotFound => e
    error_msg = "SendPaymentNotificationJob failed - record not found: #{e.message}"
    puts error_msg
    Rails.logger.error error_msg
  rescue StandardError => e
    error_msg = "SendPaymentNotificationJob failed: #{e.message}"
    error_trace = e.backtrace.join("\n")

    puts error_msg
    puts error_trace
    Rails.logger.error error_msg
    Rails.logger.error error_trace
    raise # Re-raise for retry mechanism
  end

  private

  def build_payment_message(contributions, address, head_of_family, payment, arrears_count, total_amount)
    # Determine payment method
    if payment.present?
      # QRIS payment
      payment_method = payment.payment_method
      date = payment.paid_at.strftime('%d %B %Y')
      total_display = number_to_currency(total_amount || payment.amount)
      receiver_line = ''
    elsif contributions.any?
      # Manual payment (CASH/TRANSFER)
      payment_method = contributions.first.payment_type_name
      date = contributions.first.pay_at.strftime('%d %B %Y')
      total_display = number_to_currency(total_amount || contributions.sum(&:contribution))

      # Only show receiver for CASH payment
      receiver_line = if contributions.first.payment_type == UserContribution::PAYMENT_TYPES['CASH']
                        receiver_name = contributions.first.receiver&.name&.upcase || 'PETUGAS'
                        "👤 *Diterima oleh:* #{receiver_name}\n"
                      else
                        ''
                      end
    else
      # Arrears only (no regular contributions)
      payment_method = 'CASH'
      date = Date.current.strftime('%d %B %Y')
      total_display = number_to_currency(total_amount || 0)
      receiver_line = ''
    end

    # Build items list
    items_list = []

    # Add arrears if any
    items_list << "   🔴 *Tunggakan Lama:* #{arrears_count} bulan" if arrears_count.to_i > 0

    # Add regular months if any
    if contributions.any?
      months_items = contributions.sort_by { |c| [c.year, c.month] }.map do |c|
        month_name = UserContribution::MONTHNAMES.invert[c.month]
        "   • #{month_name} #{c.year}"
      end

      if months_items.size > 10
        first_10 = months_items.first(10)
        remaining = months_items.size - 10
        items_list.concat(first_10)
        items_list << "   • dan #{remaining} bulan lainnya"
      else
        items_list.concat(months_items)
      end
    end

    items_display = items_list.join("\n")
    total_items = arrears_count.to_i + contributions.size

    <<~MESSAGE
            ✅ *Konfirmasi Pembayaran Iuran*

            Yth. Bapak/Ibu *#{head_of_family.name}*

            Pembayaran iuran berhasil:
            🏠 *Alamat:* #{address.block_address.upcase}
            💰 *Total:* #{total_display}
            📅 *Tanggal:* #{date}
            💳 *Metode:* #{payment_method}
            #{receiver_line}
            📦 *Jumlah:* #{total_items} item

            *Detail Pembayaran:*
      #{items_display}

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
