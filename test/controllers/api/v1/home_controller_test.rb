# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class HomeControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @auth_headers = @user.create_new_auth_token
        @notification = notifications(:one)

        # Create user_notification relationship
        @user_notification = UserNotification.create!(
          user: @user,
          notification: @notification,
          is_read: false
        )
      end

      # ========== Notifications List Tests ==========
      test "should get notifications list" do
        get "/api/v1/notifications",
          headers: @auth_headers,
          as: :json

        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response['success']
        assert json_response['user_notifications'].is_a?(Array)
      end

      test "should not get notifications without authentication" do
        get "/api/v1/notifications", as: :json

        assert_response :unauthorized
      end

      test "should limit notifications to 10 items" do
        # Create 15 notifications
        15.times do |i|
          notif = Notification.create!(
            title: "Test Notification #{i}",
            notif: "Test content #{i}"
          )
          UserNotification.create!(
            user: @user,
            notification: notif,
            is_read: false
          )
        end

        get "/api/v1/notifications",
          headers: @auth_headers,
          as: :json

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal 10, json_response['user_notifications'].length
      end

      test "should order notifications by created_at DESC" do
        # Create notifications with different timestamps
        old_notif = Notification.create!(
          title: "Old Notification",
          notif: "Old content",
          created_at: 2.days.ago
        )
        new_notif = Notification.create!(
          title: "New Notification",
          notif: "New content",
          created_at: 1.hour.ago
        )

        UserNotification.create!(user: @user, notification: old_notif, is_read: false)
        UserNotification.create!(user: @user, notification: new_notif, is_read: false)

        get "/api/v1/notifications",
          headers: @auth_headers,
          as: :json

        assert_response :success
        json_response = JSON.parse(response.body)

        # First notification should be the newest
        first_notif = json_response['user_notifications'].first
        assert_equal "New Notification", first_notif['notification']['title']
      end

      # ========== Notification Show Tests ==========
      test "should show notification and mark as read" do
        assert_not @user_notification.is_read

        get "/api/v1/notifications/#{@notification.id}",
          headers: @auth_headers,
          as: :json

        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response['success']
        assert_equal @notification.title, json_response['notification']['title']

        # Verify notification was marked as read
        @user_notification.reload
        assert @user_notification.is_read
      end

      test "should not show notification without authentication" do
        get "/api/v1/notifications/#{@notification.id}", as: :json

        assert_response :unauthorized
      end

      # ========== Mark Notification as Read Tests ==========
      test "should mark notification as read" do
        assert_not @user_notification.is_read

        post "/api/v1/notifications/#{@notification.id}/mark_as_read",
          headers: @auth_headers,
          as: :json

        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response['success']
        assert_equal 'Notifikasi berhasil ditandai sudah dibaca', json_response['message']

        # Verify notification was marked as read
        @user_notification.reload
        assert @user_notification.is_read
      end

      test "should handle marking already read notification" do
        @user_notification.update(is_read: true)

        post "/api/v1/notifications/#{@notification.id}/mark_as_read",
          headers: @auth_headers,
          as: :json

        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response['success']
      end

      test "should return 404 for non-existent notification" do
        post "/api/v1/notifications/99999/mark_as_read",
          headers: @auth_headers,
          as: :json

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_not json_response['success']
        assert_equal 'Notifikasi tidak ditemukan', json_response['message']
      end

      test "should not mark notification as read without authentication" do
        post "/api/v1/notifications/#{@notification.id}/mark_as_read",
          as: :json

        assert_response :unauthorized
      end

      # ========== Add Notification Tests ==========
      test "should create notification and send to all users" do
        assert_difference('Notification.count', 1) do
          post "/api/v1/notifications/add",
            params: {
              title: "New Announcement",
              notif: "This is a test announcement"
            },
            headers: @auth_headers,
            as: :json
        end

        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response['success']
        assert_equal 'notifikasi berhasil disimpan dan dikirim.', json_response['message']
      end

      test "should not create notification without authentication" do
        post "/api/v1/notifications/add",
          params: {
            title: "New Announcement",
            notif: "This is a test announcement"
          },
          as: :json

        assert_response :unauthorized
      end
    end
  end
end
