# frozen_string_literal: true

require 'net/http'
require 'json'

class ExpoPushNotificationService
  EXPO_PUSH_URL = 'https://exp.host/--/api/v2/push/send'

  # Send push notification to a single user
  # @param user [User] User object with expo_push_token
  # @param title [String] Notification title
  # @param body [String] Notification body
  # @param data [Hash] Additional data payload (optional)
  def self.send_to_user(user, title:, body:, data: {})
    return { success: false, error: 'User does not have Expo push token' } unless user.expo_push_token.present?

    send_notification(
      to: user.expo_push_token,
      title: title,
      body: body,
      data: data
    )
  end

  # Send push notification to multiple users
  # @param users [Array<User>] Array of User objects
  # @param title [String] Notification title
  # @param body [String] Notification body
  # @param data [Hash] Additional data payload (optional)
  def self.send_to_users(users, title:, body:, data: {})
    tokens = users.map(&:expo_push_token).compact
    return { success: false, error: 'No valid Expo push tokens found' } if tokens.empty?

    send_notification(
      to: tokens,
      title: title,
      body: body,
      data: data
    )
  end

  # Send push notification to all users with expo_push_token
  # @param title [String] Notification title
  # @param body [String] Notification body
  # @param data [Hash] Additional data payload (optional)
  def self.send_to_all(title:, body:, data: {})
    tokens = User.where.not(expo_push_token: nil).pluck(:expo_push_token)
    return { success: false, error: 'No users with Expo push tokens found' } if tokens.empty?

    send_notification(
      to: tokens,
      title: title,
      body: body,
      data: data
    )
  end

  # Send push notification based on block filter
  # @param block [String] Block name (A, B, C, D, F)
  # @param title [String] Notification title
  # @param body [String] Notification body
  # @param data [Hash] Additional data payload (optional)
  def self.send_to_block(block, title:, body:, data: {})
    users = User.where(pic_blok: block).where.not(expo_push_token: nil)
    send_to_users(users, title: title, body: body, data: data)
  end

  private

  # Core method to send push notification via Expo Push API
  def self.send_notification(to:, title:, body:, data: {})
    uri = URI(EXPO_PUSH_URL)

    payload = {
      to: to,
      title: title,
      body: body,
      sound: 'default',
      data: data,
      priority: 'high',
      channelId: 'default'
    }

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request.body = payload.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    result = JSON.parse(response.body)

    if response.code.to_i == 200
      { success: true, data: result }
    else
      { success: false, error: result['errors'] || 'Unknown error', data: result }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end
end
