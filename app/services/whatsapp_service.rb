class WhatsappService
  include HTTParty

  base_uri 'https://api.kirimi.id' # Update this with actual Kirimi.id API base URL

  def initialize
    @user_code = Rails.application.credentials.kirimi.user_code
    @device_id = Rails.application.credentials.kirimi.device_id
    @secret_key = Rails.application.credentials.kirimi.secret_key
    @options = {
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    }
  end

  def send_login_code(phone_number, login_code)
    message = build_login_message(login_code)
    send_message(phone_number, message)
  end

  def send_reset_password_link(phone_number, reset_link)
    message = build_reset_password_message(reset_link)
    send_message(phone_number, message)
  end

  def send_message(phone_number, message)
    body = {
      "user_code": @user_code,
      "device_id": @device_id,
      "receiver": normalize_phone_number(phone_number),
      "message": message,
      "secret": @secret_key,
      "enableTypingEffect": true,
      "typingSpeedMs": 350
    }

    response = self.class.post('/v1/send-message', @options.merge(body: body.to_json))

    handle_response(response)
  end

  private

  def build_login_message(login_code)
    <<~MESSAGE
      🏠 *PuriAyana Management System*

      Kode login Anda: *#{login_code}*

      Masukkan kode ini untuk masuk ke aplikasi.
      Kode ini akan kadaluarsa dalam 10 menit.

      Jangan bagikan kode ini kepada siapa pun.

      Terima kasih! 🙏
    MESSAGE
  end

  def build_reset_password_message(reset_link)
    <<~MESSAGE
      🏠 *PuriAyana Management System*

      Berikut tautan untuk reset password Anda:
      #{reset_link}

      Tautan ini hanya berlaku selama 5 menit.

      Jangan bagikan tautan ini kepada siapa pun.

      Terima kasih! 🙏
    MESSAGE
  end

  def normalize_phone_number(phone)
    # Remove all non-digit characters except +
    cleaned = phone.gsub(/[^\d+]/, '')

    # Add +62 for Indonesian numbers if no country code
    if cleaned.match(/^0\d+/)
      cleaned = "62#{cleaned[1..-1]}"
    elsif cleaned.match(/^8\d+/)
      cleaned = "62#{cleaned}"
    elsif !cleaned.start_with?('+')
      cleaned = "62#{cleaned}"
    end

    cleaned
  end

  def handle_response(response)
    # Debug logging
    Rails.logger.info "WhatsApp API Response: #{response.code} - #{response.body}"

    case response.code
    when 200, 201
      {
        success: true,
        message: 'Login code sent successfully',
        data: response.parsed_response
      }
    when 400
      {
        success: false,
        message: 'Invalid request parameters',
        error: response.parsed_response
      }
    when 401
      {
        success: false,
        message: 'API authentication failed',
        error: 'Invalid API key'
      }
    when 429
      {
        success: false,
        message: 'Rate limit exceeded. Please try again later.',
        error: 'Too many requests'
      }
    else
      {
        success: false,
        message: 'Failed to send WhatsApp message',
        error: response.parsed_response
      }
    end
  rescue StandardError => e
    Rails.logger.error "WhatsApp Service Error: #{e.message}"
    {
      success: false,
      message: 'Service temporarily unavailable',
      error: e.message
    }
  end
end
