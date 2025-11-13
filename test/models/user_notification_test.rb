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
require 'test_helper'

class UserNotificationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
