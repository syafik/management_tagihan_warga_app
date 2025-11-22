# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class UserControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @auth_headers = @user.create_new_auth_token
      end

      test "should register expo push token successfully" do
        expo_token = "ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]"

        post "/api/v1/user/register_push_token",
          params: { expo_push_token: expo_token },
          headers: @auth_headers,
          as: :json

        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response['success']
        assert_equal 'Push notification token berhasil didaftarkan', json_response['message']

        # Verify token was saved
        @user.reload
        assert_equal expo_token, @user.expo_push_token
      end

      test "should update existing expo push token" do
        old_token = "ExponentPushToken[old_token]"
        new_token = "ExponentPushToken[new_token]"

        @user.update(expo_push_token: old_token)

        post "/api/v1/user/register_push_token",
          params: { expo_push_token: new_token },
          headers: @auth_headers,
          as: :json

        assert_response :success
        @user.reload
        assert_equal new_token, @user.expo_push_token
      end

      test "should fail to register push token without authentication" do
        post "/api/v1/user/register_push_token",
          params: { expo_push_token: "ExponentPushToken[xxx]" },
          as: :json

        assert_response :unauthorized
      end

      test "should get user profile with expo push token" do
        @user.update(expo_push_token: "ExponentPushToken[xxx]")

        get "/api/v1/profile",
          headers: @auth_headers,
          as: :json

        assert_response :success
        json_response = JSON.parse(response.body)
        assert json_response['success']
        assert_equal "ExponentPushToken[xxx]", json_response['me']['expo_push_token']
      end
    end
  end
end
