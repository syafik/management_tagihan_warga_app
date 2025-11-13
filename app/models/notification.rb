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
end
