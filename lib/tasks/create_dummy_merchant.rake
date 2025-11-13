namespace :merchant do
  desc "Create dummy merchant user for demo/testing purposes"
  task create_dummy: :environment do
    phone = '081012345678'
    email = 'merchant@demo.com'
    address_code = 'D2'

    # Find address D2
    address = Address.find_by(block_address: address_code)

    unless address
      puts "❌ Address #{address_code} not found!"
      exit
    end

    # Check if user already exists
    user = User.find_by(phone_number: phone)

    if user
      puts "✅ User already exists: #{user.email} (ID: #{user.id})"
    else
      # Create dummy merchant user
      user = User.create!(
        name: 'Merchant Demo',
        email: email,
        phone_number: phone,
        password: 'password123',
        password_confirmation: 'password123',
        role: 1, # warga role
        pic_blok: nil,
        allow_manage_transfer: false
      )
      puts "✅ User created: #{user.email} (ID: #{user.id})"
    end

    # Link to address D2
    user_address = UserAddress.find_or_create_by(user: user, address: address) do |ua|
      ua.kk = true # Set as head of family
    end

    puts "✅ User linked to address #{address_code} (ID: #{address.id}) as head of family"
    puts ""
    puts "📋 Dummy Merchant Credentials:"
    puts "   Phone: #{phone}"
    puts "   Email: #{email}"
    puts "   Password: password123"
    puts "   Login Code: 123456 (6 digits - fixed code)"
    puts "   Address: #{address_code}"
    puts ""
    puts "⚠️  Note: This is a dummy account for merchant/testing purposes only"
  end
end
