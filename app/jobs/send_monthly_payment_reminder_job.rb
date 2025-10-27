# frozen_string_literal: true

# Job to send monthly payment reminders to residents who haven't paid
# This job should be scheduled to run on the 20th of each month
class SendMonthlyPaymentReminderJob < ApplicationJob
  queue_as :default

  def perform
    current_date = Date.current
    current_year = current_date.year
    current_month = current_date.month

    Rails.logger.info "Starting monthly payment reminder for #{current_date.strftime('%B %Y')}"

    # Get all addresses that are NOT free and have residents
    addresses = Address.includes(:user_contributions, :head_of_family, :residents)
                       .where(free: [false, nil])
                       .where.not(id: Address.left_joins(:residents).where(users: { id: nil }).select(:id))

    addresses_to_remind = []

    addresses.each do |address|
      # Check if payment has been made for current month
      payment_made = address.user_contributions.exists?(
        'EXTRACT(YEAR FROM pay_at) = ? AND EXTRACT(MONTH FROM pay_at) = ?',
        current_year,
        current_month
      )

      # Skip if already paid this month
      next if payment_made

      # Get head of family
      head_of_family = address.head_of_family
      next unless head_of_family

      # Calculate total arrears including current month
      addresses_to_remind << {
        address: address,
        head_of_family: head_of_family
      }
    end

    Rails.logger.info "Found #{addresses_to_remind.size} addresses to remind"

    # Send reminders in batches to avoid overwhelming the system
    addresses_to_remind.each_with_index do |data, index|
      # Add delay between messages (stagger by 5 seconds each)
      delay_seconds = index * 5

      SendPaymentReminderNotificationJob.set(wait: delay_seconds.seconds).perform_later(
        data[:address].id,
        current_year,
        current_month
      )
    end

    Rails.logger.info "Queued #{addresses_to_remind.size} payment reminder notifications"

    {
      success: true,
      total_reminders: addresses_to_remind.size,
      month: current_date.strftime('%B %Y')
    }
  rescue StandardError => e
    Rails.logger.error "SendMonthlyPaymentReminderJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
