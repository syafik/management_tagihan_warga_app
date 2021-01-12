# frozen_string_literal: true

class UserNotification < ApplicationRecord

  belongs_to :user
  belongs_to :notification
  
end
