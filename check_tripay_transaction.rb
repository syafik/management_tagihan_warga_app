#!/usr/bin/env ruby
# Script untuk cek status transaksi di Tripay
# Usage: ruby check_tripay_transaction.rb [payment_reference]

require 'bundler/setup'
require 'httparty'
require 'json'

# Load Rails environment
require_relative 'config/environment'

# Get payment
reference = ARGV[0]

if reference
  payment = Payment.find_by(reference: reference)
  unless payment
    puts "❌ Payment not found: #{reference}"
    exit 1
  end
else
  payment = Payment.last
  unless payment
    puts "❌ No payment found"
    exit 1
  end
end

puts "=" * 70
puts "🔍 TRIPAY TRANSACTION STATUS CHECKER"
puts "=" * 70

puts "\n📋 LOCAL PAYMENT INFO:"
puts "  Reference  : #{payment.reference}"
puts "  Status     : #{payment.status}"
puts "  Amount     : Rp #{payment.amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
puts "  Created At : #{payment.created_at}"

# Get Tripay credentials
credentials = Rails.application.credentials.tripay
api_key = credentials[:api_key]
base_url = credentials[:base_url]

puts "\n🌐 CHECKING TRIPAY SERVER..."
puts "  API URL: #{base_url}"
puts "  Merchant: #{credentials[:merchant_code]}"

# Check transaction detail from Tripay
begin
  response = HTTParty.get(
    "#{base_url}/transaction/detail",
    headers: {
      'Authorization' => "Bearer #{api_key}"
    },
    query: {
      reference: payment.reference
    },
    timeout: 10
  )

  if response.code == 200
    data = JSON.parse(response.body)

    if data['success']
      tripay_data = data['data']

      puts "\n✅ TRIPAY TRANSACTION FOUND!"
      puts "\n📊 TRIPAY STATUS:"
      puts "  Reference       : #{tripay_data['reference']}"
      puts "  Merchant Ref    : #{tripay_data['merchant_ref']}"
      puts "  Status          : #{tripay_data['status']}"
      puts "  Payment Method  : #{tripay_data['payment_method']}"
      puts "  Amount          : Rp #{tripay_data['amount'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
      puts "  Fee             : Rp #{tripay_data['total_fee'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"

      if tripay_data['paid_at']
        puts "  Paid At         : #{Time.at(tripay_data['paid_at']).strftime('%Y-%m-%d %H:%M:%S')}"
      end

      if tripay_data['expired_time']
        expired = Time.at(tripay_data['expired_time'])
        puts "  Expired At      : #{expired.strftime('%Y-%m-%d %H:%M:%S')}"

        if expired < Time.current
          puts "  ⚠️  Transaction EXPIRED"
        else
          remaining = expired - Time.current
          puts "  ⏱️  Time Remaining  : #{(remaining / 60).to_i} minutes"
        end
      end

      puts "\n📱 PAYMENT URLS:"
      puts "  Checkout: #{tripay_data['checkout_url']}" if tripay_data['checkout_url']
      puts "  QR Code : #{tripay_data['qr_url']}" if tripay_data['qr_url']

      # Compare status
      puts "\n🔄 STATUS COMPARISON:"
      puts "  Local DB : #{payment.status}"
      puts "  Tripay   : #{tripay_data['status']}"

      if payment.status != tripay_data['status']
        puts "  ⚠️  STATUS MISMATCH!"
        puts "\n💡 To sync, you can:"
        puts "  1. Use test script: ruby test_tripay_callback.rb #{payment.reference}"
        puts "  2. Or update manually via Tripay dashboard"
      else
        puts "  ✅ Status in sync"
      end

      # Instructions for sandbox
      if tripay_data['status'] == 'UNPAID'
        puts "\n" + "=" * 70
        puts "📖 HOW TO MARK AS PAID (SANDBOX MODE):"
        puts "=" * 70

        puts "\nOption A: Via Tripay Dashboard"
        puts "  1. Login: https://tripay.co.id/merchant/login"
        puts "  2. Go to: Transaksi > Closed Payment"
        puts "  3. Find: #{payment.reference}"
        puts "  4. Click: 'Mark as Paid' button"
        puts "  5. Tripay will send callback automatically"

        puts "\nOption B: Via Test Script (Simulate Callback)"
        puts "  $ ruby test_tripay_callback.rb #{payment.reference}"

        puts "\nOption C: Scan QR Code (Need ngrok/cloudflared)"
        puts "  1. Expose local: ngrok http 5100"
        puts "  2. Update callback URL in Tripay settings"
        puts "  3. Scan QR: #{tripay_data['qr_url']}"
        puts "  4. Pay via sandbox e-wallet"
      end

    else
      puts "\n❌ TRIPAY ERROR: #{data['message']}"
    end

  else
    puts "\n❌ HTTP ERROR: #{response.code}"
    puts response.body
  end

rescue => e
  puts "\n❌ ERROR: #{e.message}"
  puts "\n💡 Make sure you have internet connection"
end

puts "\n" + "=" * 70
