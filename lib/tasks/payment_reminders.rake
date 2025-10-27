# frozen_string_literal: true

namespace :payment_reminders do
  desc 'Send monthly payment reminders to residents who haven\'t paid (manually trigger)'
  task send: :environment do
    puts "Starting monthly payment reminder job..."
    puts "Current date: #{Date.current.strftime('%d %B %Y')}"
    puts "=" * 80

    result = SendMonthlyPaymentReminderJob.perform_now

    puts "\n" + "=" * 80
    puts "✅ Job completed successfully!"
    puts "Total reminders queued: #{result[:total_reminders]}"
    puts "Month: #{result[:month]}"
    puts "=" * 80
  rescue StandardError => e
    puts "\n" + "=" * 80
    puts "❌ Job failed with error:"
    puts e.message
    puts e.backtrace.first(5).join("\n")
    puts "=" * 80
    exit 1
  end

  desc 'Preview who will receive payment reminders (dry run)'
  task preview: :environment do
    current_date = Date.current
    current_year = current_date.year
    current_month = current_date.month

    puts "Payment Reminder Preview"
    puts "Current date: #{current_date.strftime('%d %B %Y')}"
    puts "=" * 80

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

      next if payment_made

      head_of_family = address.head_of_family
      next unless head_of_family

      # Calculate total arrears
      start_date = Date.new(2025, 1, 1)
      months_should_pay = ((current_date.year - start_date.year) * 12) + (current_date.month - start_date.month) + 1
      total_paid_2025 = address.user_contributions
                               .where('pay_at >= ? AND pay_at <= ?', start_date, current_date.end_of_month)
                               .count
      initial_arrears = address.arrears || 0
      total_arrears = months_should_pay - total_paid_2025 + initial_arrears

      addresses_to_remind << {
        address: address.block_address.upcase,
        name: head_of_family.name,
        phone: head_of_family.phone_number,
        arrears: total_arrears
      }
    end

    if addresses_to_remind.empty?
      puts "\n✅ No reminders needed - all residents have paid for #{Date::MONTHNAMES[current_month]}!"
    else
      puts "\n📋 Residents who will receive reminders (#{addresses_to_remind.size} total):"
      puts "-" * 80
      printf("%-15s %-30s %-20s %s\n", "Address", "Name", "Phone", "Total Arrears")
      puts "-" * 80

      addresses_to_remind.each do |data|
        printf("%-15s %-30s %-20s %d bulan\n",
               data[:address],
               data[:name].truncate(28),
               data[:phone],
               data[:arrears])
      end

      puts "-" * 80
      puts "\nTotal: #{addresses_to_remind.size} reminders will be sent"
    end

    puts "=" * 80
  end

  desc 'Send test reminder to a specific address (usage: rake payment_reminders:test[A12])'
  task :test, [:block_address] => :environment do |_t, args|
    block_address = args[:block_address]

    if block_address.blank?
      puts "❌ Error: Please provide a block address"
      puts "Usage: rake payment_reminders:test[A12]"
      exit 1
    end

    address = Address.find_by(block_address: block_address)

    unless address
      puts "❌ Error: Address '#{block_address}' not found"
      exit 1
    end

    head_of_family = address.head_of_family

    unless head_of_family
      puts "❌ Error: No head of family found for address '#{block_address}'"
      exit 1
    end

    puts "Sending test payment reminder..."
    puts "Address: #{address.block_address.upcase}"
    puts "Recipient: #{head_of_family.name}"
    puts "Phone: #{head_of_family.phone_number}"
    puts "=" * 80

    current_date = Date.current
    SendPaymentReminderNotificationJob.perform_now(
      address.id,
      current_date.year,
      current_date.month
    )

    puts "\n✅ Test reminder sent successfully!"
    puts "=" * 80
  rescue StandardError => e
    puts "\n❌ Failed to send test reminder:"
    puts e.message
    puts e.backtrace.first(5).join("\n")
    exit 1
  end
end
