# frozen_string_literal: true

class UserNotification < ApplicationRecord

  belongs_to :user
  belongs_to :notification

  def notif_sent_at
    created_at.strftime('%d %B %Y')
  end
  
end
