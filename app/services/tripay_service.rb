class TripayService
  class TripayError < StandardError; end

  def initialize
    @credentials = Rails.application.credentials.tripay
    @api_key = @credentials[:api_key]
    @private_key = @credentials[:private_key]
    @merchant_code = @credentials[:merchant_code]
    @base_url = @credentials[:base_url]
    # Payment method can be configured in credentials or use default
    # Sandbox: QRIS2 or QRISC
    # Production: QRIS (after enabled in Tripay dashboard)
    @payment_method = @credentials[:payment_method] || 'QRIS2'
  end

  # Create closed payment transaction (QRIS)
  def create_transaction(user:, address:, amount:, months: [], return_url: nil)
    reference = generate_reference

    # Build return URL - use provided or construct from host
    payment_return_url = return_url || build_return_url(reference)

    payload = {
      method: @payment_method,
      merchant_ref: reference,
      amount: amount.to_i,
      customer_name: user.name,
      customer_email: user.email || "#{user.phone_number}@placeholder.com",
      customer_phone: user.phone_number.gsub('+62', '0'),
      order_items: build_order_items(months, amount),
      return_url: payment_return_url,
      expired_time: (Time.current + 2.hours).to_i,
      signature: generate_signature(reference, amount.to_i)
    }

    response = HTTParty.post(
      "#{@base_url}/transaction/create",
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/json'
      },
      body: payload.to_json
    )

    handle_response(response)
  end

  # Get transaction detail
  def get_transaction_detail(reference)
    response = HTTParty.get(
      "#{@base_url}/transaction/detail",
      headers: {
        'Authorization' => "Bearer #{@api_key}"
      },
      query: { reference: reference }
    )

    handle_response(response)
  end

  # Calculate fee for given amount (borne by customer)
  def calculate_fee(amount)
    # Tripay QRIS fee: 0.7% + Rp 750
    fee_percentage = amount * 0.007
    fee_fixed = 750
    (fee_percentage + fee_fixed).round
  end

  # Calculate total amount including fee
  def calculate_total_with_fee(contribution_amount)
    fee = calculate_fee(contribution_amount)
    {
      contribution: contribution_amount,
      fee: fee,
      total: contribution_amount + fee
    }
  end

  # Verify callback signature
  def verify_callback_signature(signature, json_payload)
    # Tripay uses HMAC SHA256 with private key and the entire JSON payload
    expected = OpenSSL::HMAC.hexdigest(
      'sha256',
      @private_key,
      json_payload
    )

    signature == expected
  end

  private

  def build_return_url(reference)
    # Try to get from ENV first
    base_url = ENV['APP_URL'] || ENV['RAILS_HOST']

    if base_url.present?
      # Remove trailing slash if present
      base_url = base_url.chomp('/')
      return "#{base_url}/payments/#{reference}"
    end

    # Fallback: construct from Rails default host
    # For development, use localhost:3000
    # For production, this should be set in ENV
    if Rails.env.development?
      "http://localhost:5100/payments/#{reference}"
    else
      # In production, you MUST set APP_URL environment variable
      raise TripayError, "APP_URL environment variable is not set. Required for return_url."
    end
  end

  def generate_reference
    timestamp = Time.current.to_i
    random = SecureRandom.hex(4).upcase
    "PAY#{timestamp}#{random}"
  end

  def generate_signature(merchant_ref, amount)
    OpenSSL::HMAC.hexdigest(
      'sha256',
      @private_key,
      "#{@merchant_code}#{merchant_ref}#{amount}"
    )
  end

  def build_order_items(months, total_amount)
    if months.empty?
      [{
        name: 'Iuran Bulanan',
        price: total_amount.to_i,
        quantity: 1
      }]
    else
      [{
        name: "Iuran Bulanan (#{months.size} bulan)",
        price: total_amount.to_i,
        quantity: 1
      }]
    end
  end

  def handle_response(response)
    parsed = JSON.parse(response.body)

    unless parsed['success']
      error_message = parsed.dig('message') || 'Unknown error'
      raise TripayError, "Tripay API error: #{error_message}"
    end

    parsed['data']
  rescue JSON::ParserError => e
    raise TripayError, "Failed to parse Tripay response: #{e.message}"
  end
end
