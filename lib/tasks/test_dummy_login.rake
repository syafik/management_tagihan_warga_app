namespace :merchant do
  desc "Test dummy merchant login code"
  task test_login: :environment do
    user = User.find_by(phone_number: '+6281012345678')

    unless user
      puts "❌ Dummy merchant user not found!"
      exit
    end

    puts "Testing dummy merchant login..."
    puts ""

    # Test send login code
    puts "1. Sending login code..."
    result = user.send_login_code!
    puts "   Result: #{result[:message]}"

    user.reload
    puts "   Login code: #{user.login_code}"
    puts "   Expires at: #{user.login_code_expires_at}"
    puts ""

    # Test code validation
    puts "2. Testing code validation..."
    puts "   Code '123456' valid? #{user.login_code_valid?('123456')}"
    puts "   Code '999999' valid? #{user.login_code_valid?('999999')}"
    puts ""

    puts "✅ All tests passed!"
    puts ""
    puts "You can now login with:"
    puts "   Phone: 081012345678"
    puts "   Code: 123456"
  end
end
