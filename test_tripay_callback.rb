#!/usr/bin/env ruby
# Test script untuk simulate Tripay webhook callback
# Usage: ruby test_tripay_callback.rb [payment_reference]

require 'bundler/setup'
require 'httparty'
require 'json'
require 'openssl'

# Load Rails environment to access database
require_relative 'config/environment'

# Get payment reference from argument or use last payment
reference = ARGV[0]

if reference
  payment = Payment.find_by(reference: reference)
  unless payment
    puts "❌ Payment not found: #{reference}"
    exit 1
  end
else
  payment = Payment.where(status: 'UNPAID').last
  unless payment
    puts "❌ No unpaid payment found. Please create a payment first."
    exit 1
  end
end

puts "=" * 70
puts "🧪 TRIPAY WEBHOOK CALLBACK SIMULATOR"
puts "=" * 70

puts "\n📋 PAYMENT INFO:"
puts "  Reference    : #{payment.reference}"
puts "  Amount       : Rp #{payment.amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
puts "  Status       : #{payment.status}"
puts "  User         : #{payment.user.name}"
puts "  Address      : #{payment.address.block_address}"
puts "  Created At   : #{payment.created_at}"

# Check payment notes to see what will be processed
if payment.notes.present?
  json_match = payment.notes.match(/\[.*\]/)
  if json_match
    months_data = JSON.parse(json_match[0])
    puts "\n📦 ITEMS TO PROCESS:"
    months_data.each do |item|
      if item['type'] == 'arrears'
        puts "  ⚠️  Tunggakan ##{item['arrears_index']} - Rp #{item['amount']}"
      else
        puts "  📅 #{item['year']}-#{item['month']} - Rp #{item['amount']}"
      end
    end
  end
end

# Get address arrears before
address_arrears_before = payment.address.arrears

# Tripay credentials
credentials = Rails.application.credentials.tripay
private_key = credentials[:private_key]
merchant_ref = payment.reference
amount = payment.amount.to_i
status = 'PAID'

# Prepare callback payload (same format as Tripay sends)
callback_payload = {
  reference: "DEV-T42682#{rand(100000000..999999999)}",
  merchant_ref: merchant_ref,
  payment_method: 'QRIS',
  payment_method_code: 'QRIS2',
  total_amount: amount,
  fee_merchant: (amount * 0.007 + 750).to_i,
  fee_customer: 0,
  total_fee: (amount * 0.007 + 750).to_i,
  amount_received: amount - (amount * 0.007 + 750).to_i,
  is_closed_payment: 1,
  status: status,
  paid_at: Time.current.to_i,
  note: 'test'
}

# Generate signature using the entire JSON payload (same as Tripay)
json_payload = callback_payload.to_json
signature = OpenSSL::HMAC.hexdigest(
  'sha256',
  private_key,
  json_payload
)

puts "\n🔐 SIGNATURE:"
puts "  #{signature}"
puts "\n📦 PAYLOAD:"
puts "  #{json_payload}"

puts "\n🚀 SENDING CALLBACK..."
puts "  URL: http://localhost:5100/tripay/callback"
puts "  Method: POST"
puts "  Header: X-Callback-Signature"

# Send POST request
begin
  response = HTTParty.post(
    'http://localhost:5100/tripay/callback',
    headers: {
      'X-Callback-Signature' => signature,
      'Content-Type' => 'application/json'
    },
    body: json_payload,
    timeout: 10
  )

  puts "\n📨 RESPONSE:"
  puts "  Status: #{response.code}"
  puts "  Body: #{response.body}"

  if response.code == 200
    puts "\n✅ CALLBACK SUCCESS!"
  else
    puts "\n❌ CALLBACK FAILED!"
    exit 1
  end
rescue => e
  puts "\n❌ ERROR: #{e.message}"
  puts "\n💡 Make sure Rails server is running on port 5100"
  exit 1
end

# Reload and check results
sleep 1
payment.reload
address = payment.address
address.reload

puts "\n" + "=" * 70
puts "🎯 VERIFICATION RESULTS"
puts "=" * 70

puts "\n💳 Payment Status:"
puts "  Before: UNPAID"
puts "  After : #{payment.status}"
puts "  Paid At: #{payment.paid_at}"

if payment.paid?
  puts "  ✅ Payment marked as PAID"
else
  puts "  ❌ Payment NOT marked as PAID"
end

puts "\n📊 User Contributions:"
contributions = UserContribution.where("description LIKE ?", "%#{payment.reference}%")
if contributions.any?
  contributions.each do |uc|
    month_name = UserContribution::MONTHNAMES.invert[uc.month]
    puts "  ✅ #{uc.year}-#{month_name}: Rp #{uc.contribution.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
  end
else
  puts "  ⚠️  No contributions created"
end

puts "\n⚠️  Address Arrears:"
puts "  Address: #{address.block_address}"
puts "  Before : #{address_arrears_before} bulan"
puts "  After  : #{address.arrears} bulan"

if address_arrears_before > address.arrears
  puts "  ✅ Arrears reduced by #{address_arrears_before - address.arrears}"
elsif address_arrears_before == address.arrears && address.arrears > 0
  puts "  ℹ️  Arrears unchanged (no arrears in payment)"
elsif address_arrears_before == 0
  puts "  ℹ️  No arrears to reduce"
end

puts "\n" + "=" * 70
puts "✅ TEST COMPLETE!"
puts "=" * 70
