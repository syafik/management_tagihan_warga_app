# frozen_string_literal: true

require 'test_helper'

class ExpoPushNotificationServiceTest < ActiveSupport::TestCase
  setup do
    @user_with_token = users(:one)
    @user_with_token.update(expo_push_token: "ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]")

    @user_without_token = users(:two)
    @user_without_token.update(expo_push_token: nil)

    @notification_data = {
      title: "Test Notification",
      body: "This is a test notification",
      data: { notification_id: 1, type: 'payment' }
    }
  end

  # ========== send_to_user Tests ==========
  test "should send push notification to user with token" do
    # Mock the HTTP request
    stub_request(:post, ExpoPushNotificationService::EXPO_PUSH_URL)
      .with(
        body: hash_including(
          to: @user_with_token.expo_push_token,
          title: @notification_data[:title],
          body: @notification_data[:body]
        )
      )
      .to_return(
        status: 200,
        body: { data: [{ status: 'ok' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = ExpoPushNotificationService.send_to_user(
      @user_with_token,
      title: @notification_data[:title],
      body: @notification_data[:body],
      data: @notification_data[:data]
    )

    assert result[:success]
    assert result[:data].is_a?(Hash)
  end

  test "should fail to send to user without token" do
    result = ExpoPushNotificationService.send_to_user(
      @user_without_token,
      title: @notification_data[:title],
      body: @notification_data[:body]
    )

    assert_not result[:success]
    assert_equal 'User does not have Expo push token', result[:error]
  end

  # ========== send_to_users Tests ==========
  test "should send push notification to multiple users" do
    user2 = User.create!(
      name: "User 2",
      phone_number: "+628123456789",
      expo_push_token: "ExponentPushToken[yyyyyyyyyyyyyyyyyyyy]",
      password: "password123"
    )

    users = [@user_with_token, user2]
    tokens = users.map(&:expo_push_token)

    stub_request(:post, ExpoPushNotificationService::EXPO_PUSH_URL)
      .with(
        body: hash_including(
          to: tokens,
          title: @notification_data[:title],
          body: @notification_data[:body]
        )
      )
      .to_return(
        status: 200,
        body: { data: [{ status: 'ok' }, { status: 'ok' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = ExpoPushNotificationService.send_to_users(
      users,
      title: @notification_data[:title],
      body: @notification_data[:body],
      data: @notification_data[:data]
    )

    assert result[:success]
  ensure
    user2&.destroy
  end

  test "should filter out users without tokens when sending to multiple" do
    users = [@user_with_token, @user_without_token]

    stub_request(:post, ExpoPushNotificationService::EXPO_PUSH_URL)
      .with(
        body: hash_including(
          to: [@user_with_token.expo_push_token]
        )
      )
      .to_return(
        status: 200,
        body: { data: [{ status: 'ok' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = ExpoPushNotificationService.send_to_users(
      users,
      title: @notification_data[:title],
      body: @notification_data[:body]
    )

    assert result[:success]
  end

  test "should fail when no users have tokens" do
    users = [@user_without_token]

    result = ExpoPushNotificationService.send_to_users(
      users,
      title: @notification_data[:title],
      body: @notification_data[:body]
    )

    assert_not result[:success]
    assert_equal 'No valid Expo push tokens found', result[:error]
  end

  # ========== send_to_all Tests ==========
  test "should send to all users with expo_push_token" do
    # Ensure at least one user has a token
    @user_with_token.update(expo_push_token: "ExponentPushToken[test]")

    stub_request(:post, ExpoPushNotificationService::EXPO_PUSH_URL)
      .to_return(
        status: 200,
        body: { data: [{ status: 'ok' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = ExpoPushNotificationService.send_to_all(
      title: @notification_data[:title],
      body: @notification_data[:body]
    )

    assert result[:success]
  end

  # ========== Error Handling Tests ==========
  test "should handle API errors gracefully" do
    stub_request(:post, ExpoPushNotificationService::EXPO_PUSH_URL)
      .to_return(
        status: 400,
        body: { errors: [{ message: 'Invalid token' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = ExpoPushNotificationService.send_to_user(
      @user_with_token,
      title: @notification_data[:title],
      body: @notification_data[:body]
    )

    assert_not result[:success]
    assert result[:error].present?
  end

  test "should handle network errors" do
    stub_request(:post, ExpoPushNotificationService::EXPO_PUSH_URL)
      .to_raise(StandardError.new("Network error"))

    result = ExpoPushNotificationService.send_to_user(
      @user_with_token,
      title: @notification_data[:title],
      body: @notification_data[:body]
    )

    assert_not result[:success]
    assert_equal 'Network error', result[:error]
  end

  # ========== Payload Validation Tests ==========
  test "should include correct payload structure" do
    stub_request(:post, ExpoPushNotificationService::EXPO_PUSH_URL)
      .with { |request|
        body = JSON.parse(request.body)
        assert_equal @user_with_token.expo_push_token, body['to']
        assert_equal @notification_data[:title], body['title']
        assert_equal @notification_data[:body], body['body']
        assert_equal 'default', body['sound']
        assert_equal 'high', body['priority']
        assert_equal 'default', body['channelId']
        assert_equal @notification_data[:data], body['data'].symbolize_keys
        true
      }
      .to_return(
        status: 200,
        body: { data: [{ status: 'ok' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    ExpoPushNotificationService.send_to_user(
      @user_with_token,
      title: @notification_data[:title],
      body: @notification_data[:body],
      data: @notification_data[:data]
    )
  end
end
