# frozen_string_literal: true

# Job to send WhatsApp payment notification to head of family
# Supports both single and multiple contributions
class SendPaymentNotificationJob < ApplicationJob
  queue_as :default

  # Can accept:
  # - Single ID: perform(123) → send for 1 contribution
  # - Array of IDs: perform([123, 124, 125]) → send bulk message for multiple contributions
  # - With payment details: perform([123, 124], payment_id, arrears_count, total_amount)
  def perform(user_contribution_ids, payment_id = nil, arrears_count = 0, total_amount = nil)
    user_contribution_ids = Array(user_contribution_ids)

    # Get contributions
    contributions = UserContribution.where(id: user_contribution_ids).includes(:address, :receiver)

    # If we have payment_id, get address from payment (handles arrears-only payments)
    if payment_id.present?
      payment = Payment.find_by(id: payment_id)
      address = payment&.address
      head_of_family = address&.head_of_family
    elsif contributions.any?
      # Get address and head of family from first contribution
      address = contributions.first.address
      head_of_family = address.head_of_family
    else
      return # No contributions and no payment
    end

    # Skip if no head of family found
    return unless head_of_family && address

    whatsapp_service = WhatsappService.new

    # Build message based on what we have
    if payment_id.present? && (contributions.any? || arrears_count > 0)
      # Payment via QRIS with possible arrears
      Rails.logger.info "Sending payment notification with arrears (#{arrears_count}) to #{head_of_family.phone_number}"
      message = build_payment_with_arrears_message(contributions, address, head_of_family, arrears_count, total_amount, payment)
    elsif contributions.size > 1
      Rails.logger.info "Sending bulk payment notification (#{contributions.size} months) to #{head_of_family.phone_number}"
      message = build_bulk_payment_message(contributions, address, head_of_family)
    elsif contributions.size == 1
      Rails.logger.info "Sending payment notification to #{head_of_family.phone_number} for address #{address.block_address}"
      message = build_single_payment_message(contributions.first, address, head_of_family)
    else
      return # Nothing to send
    end

    # Log message before sending (to both stdout and log file)
    log_message = <<~LOG
      #{"="*80}
      Sending WhatsApp notification to #{head_of_family.phone_number}
      Message content:
      #{message}
      #{"="*80}
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

  def build_payment_with_arrears_message(contributions, address, head_of_family, arrears_count, total_amount, payment)
    total_display = number_to_currency(total_amount || contributions.sum(&:contribution))
    date = payment.paid_at.strftime('%d %B %Y')
    payment_method = payment.payment_method

    # Build items list
    items_list = []

    # Add arrears if any
    if arrears_count > 0
      items_list << "   🔴 *Tunggakan Lama:* #{arrears_count} bulan"
    end

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
    total_items = arrears_count + contributions.size

    <<~MESSAGE
      ✅ *Konfirmasi Pembayaran Iuran*

      Yth. Bapak/Ibu *#{head_of_family.name}*

      Pembayaran iuran berhasil:
      🏠 *Alamat:* #{address.block_address.upcase}
      💰 *Total:* #{total_display}
      📅 *Tanggal:* #{date}
      💳 *Metode:* #{payment_method}
      📦 *Jumlah:* #{total_items} item

      *Detail Pembayaran:*
#{items_display}

      Terima kasih atas partisipasi Anda dalam menjaga lingkungan Puri Ayana.

      Untuk informasi lebih lanjut, silakan akses aplikasi di https://app.puriayana.com

      Salam,
      Pengurus Puri Ayana 🏡
    MESSAGE
  end

  def build_single_payment_message(user_contribution, address, head_of_family)
    payment_method = user_contribution.payment_type_name
    amount = number_to_currency(user_contribution.contribution)
    date = user_contribution.pay_at.strftime('%d %B %Y')

    # Only show receiver for CASH payment
    receiver_line = if user_contribution.payment_type == UserContribution::PAYMENT_TYPES['CASH']
      receiver_name = user_contribution.receiver&.name&.upcase || 'PETUGAS'
      "👤 *Diterima oleh:* #{receiver_name}\n"
    else
      ""
    end

    <<~MESSAGE
      ✅ *Konfirmasi Pembayaran Iuran*

      Yth. Bapak/Ibu *#{head_of_family.name}*

      Pembayaran iuran untuk:
      🏠 *Alamat:* #{address.block_address.upcase}
      💰 *Nominal:* #{amount}
      📅 *Tanggal:* #{date}
      💳 *Metode:* #{payment_method}
      #{receiver_line.chomp}
      Terima kasih atas partisipasi Anda dalam menjaga lingkungan Puri Ayana.

      Untuk informasi lebih lanjut, silakan akses aplikasi di https://app.puriayana.com

      Salam,
      Pengurus Puri Ayana 🏡
    MESSAGE
  end

  def build_bulk_payment_message(contributions, address, head_of_family)
    total_amount = number_to_currency(contributions.sum(&:contribution))
    date = contributions.first.pay_at.strftime('%d %B %Y')
    payment_method = contributions.first.payment_type_name
    month_count = contributions.size

    # Only show receiver for CASH payment
    receiver_line = if contributions.first.payment_type == UserContribution::PAYMENT_TYPES['CASH']
      receiver_name = contributions.first.receiver&.name&.upcase || 'PETUGAS'
      "👤 *Diterima oleh:* #{receiver_name}\n"
    else
      ""
    end

    # Build month list (max 10 items, then "dan X lainnya")
    months_list = contributions.sort_by { |c| [c.year, c.month] }.map do |c|
      month_name = UserContribution::MONTHNAMES.invert[c.month]
      "   • #{month_name} #{c.year}"
    end

    if months_list.size > 10
      first_10 = months_list.first(10).join("\n")
      remaining = months_list.size - 10
      months_list = "#{first_10}\n   • dan #{remaining} bulan lainnya"
    else
      months_list = months_list.join("\n")
    end

    <<~MESSAGE
      ✅ *Konfirmasi Pembayaran Iuran*

      Yth. Bapak/Ibu *#{head_of_family.name}*

      Pembayaran iuran berhasil:
      🏠 *Alamat:* #{address.block_address.upcase}
      💰 *Total:* #{total_amount}
      📅 *Tanggal:* #{date}
      💳 *Metode:* #{payment_method}
      #{receiver_line}📦 *Jumlah:* #{month_count} bulan

      *Detail Pembayaran:*
#{months_list}

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
