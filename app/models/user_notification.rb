# frozen_string_literal: true

# == Schema Information
#
# Table name: user_notifications
#
#  id              :bigint           not null, primary key
#  is_read         :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  notification_id :integer
#  user_id         :integer
#
# Indexes
#
#  index_user_notifications_on_notification_id_and_user_id  (notification_id,user_id)
#
class UserNotification < ApplicationRecord

  belongs_to :user
  belongs_to :notification

  def notif_sent_at
    created_at.strftime('%d %B %Y')
  end
  
end
