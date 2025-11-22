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
class Notification < ApplicationRecord
  
  validates :title, :notif, presence: true
  has_many :user_notifications
  has_many :users, through: :user_notifications
  has_many :app_notif_receivers, -> { where('device_token IS NOT NULL') }, through: :user_notifications,  source: :user

  after_create :send_push_notifications

  before_destroy do
    UserNotification.where(notification_id: self.id).delete_all
  end

  def self.ransack_predicates
    [
      %w[Contains cont],
      %w[Equal eq]
    ]
  end

  def read_by(user)
    user_notifications.where(user_id: user.id).update(is_read: true)
  end

  def self.clear_expired_notifications
    where('notifications.created_at < ?', 1.month.ago).destroy_all
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "notif", "title", "updated_at", "user_id"]
  end

  private

  def send_push_notifications
    # Send push notification to target users
    target_users = if users.any?
                     # Send to specific users if assigned
                     users.where.not(expo_push_token: nil)
                   else
                     # Send to all users with push tokens if no specific users
                     User.where.not(expo_push_token: nil)
                   end

    return if target_users.empty?

    ExpoPushNotificationService.send_to_users(
      target_users,
      title: title,
      body: notif,
      data: { notification_id: id, type: 'notification' }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to send push notification: #{e.message}"
  end
end
