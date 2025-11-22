# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id         :bigint           not null, primary key
#  notif      :text
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  index_notifications_on_user_id  (user_id)
#
require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  setup do
    @user_with_token = users(:one)
    @user_with_token.update(expo_push_token: "ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]")

    @user_without_token = users(:two)
    @user_without_token.update(expo_push_token: nil)
  end

  # ========== Validation Tests ==========
  test "should not save notification without title" do
    notification = Notification.new(notif: "Test notification body")
    assert_not notification.save
    assert_includes notification.errors[:title], "can't be blank"
  end

  test "should not save notification without body" do
    notification = Notification.new(title: "Test Title")
    assert_not notification.save
    assert_includes notification.errors[:notif], "can't be blank"
  end

  test "should save valid notification" do
    notification = Notification.new(
      title: "Test Title",
      notif: "Test notification body"
    )
    assert notification.save
  end

  # ========== Association Tests ==========
  test "should have many user_notifications" do
    notification = Notification.create!(
      title: "Test Notification",
      notif: "Test content"
    )

    UserNotification.create!(user: @user_with_token, notification: notification)
    UserNotification.create!(user: @user_without_token, notification: notification)

    assert_equal 2, notification.user_notifications.count
  end

  test "should have many users through user_notifications" do
    notification = Notification.create!(
      title: "Test Notification",
      notif: "Test content"
    )

    UserNotification.create!(user: @user_with_token, notification: notification)
    UserNotification.create!(user: @user_without_token, notification: notification)

    assert_equal 2, notification.users.count
    assert_includes notification.users, @user_with_token
    assert_includes notification.users, @user_without_token
  end

  # ========== read_by Method Tests ==========
  test "should mark notification as read for user" do
    notification = Notification.create!(
      title: "Test Notification",
      notif: "Test content"
    )

    user_notification = UserNotification.create!(
      user: @user_with_token,
      notification: notification,
      is_read: false
    )

    assert_not user_notification.is_read

    notification.read_by(@user_with_token)

    user_notification.reload
    assert user_notification.is_read
  end

  test "should only mark as read for specific user" do
    notification = Notification.create!(
      title: "Test Notification",
      notif: "Test content"
    )

    user_notif_1 = UserNotification.create!(
      user: @user_with_token,
      notification: notification,
      is_read: false
    )

    user_notif_2 = UserNotification.create!(
      user: @user_without_token,
      notification: notification,
      is_read: false
    )

    notification.read_by(@user_with_token)

    user_notif_1.reload
    user_notif_2.reload

    assert user_notif_1.is_read
    assert_not user_notif_2.is_read
  end

  # ========== clear_expired_notifications Tests ==========
  test "should delete notifications older than 1 month" do
    old_notification = Notification.create!(
      title: "Old Notification",
      notif: "This is old",
      created_at: 2.months.ago
    )

    recent_notification = Notification.create!(
      title: "Recent Notification",
      notif: "This is recent",
      created_at: 1.week.ago
    )

    Notification.clear_expired_notifications

    assert_not Notification.exists?(old_notification.id)
    assert Notification.exists?(recent_notification.id)
  end

  # ========== Cascade Delete Tests ==========
  test "should delete user_notifications when notification is deleted" do
    notification = Notification.create!(
      title: "Delete Test",
      notif: "Test cascade delete"
    )

    user_notification = UserNotification.create!(
      user: @user_with_token,
      notification: notification
    )

    notification.destroy

    assert_not UserNotification.exists?(user_notification.id)
  end
end
