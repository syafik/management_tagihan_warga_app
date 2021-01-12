# frozen_string_literal: true

class Notification < ApplicationRecord
  
  validates :title, :notif, presence: true
  has_many :user_notifications
  has_many :users, through: :user_notifications
  has_many :app_notif_receivers, -> { where('device_token IS NOT NULL') }, through: :user_notifications,  source: :user

  def self.ransack_predicates
    [
      %w[Contains cont],
      %w[Equal eq]
    ]
  end
  
end
