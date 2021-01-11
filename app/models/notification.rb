# frozen_string_literal: true

class Notification < ApplicationRecord
  after_create :send_mobile_notification

  def self.ransack_predicates
    [
      %w[Contains cont],
      %w[Equal eq]
    ]
  end

 private def send_mobile_notification
   device_tokens = User.select('device_token').where("device_token IS NOT NULL AND device_type = 'android'").pluck(:device_token)
   request = Typhoeus::Request.new(
    "https://fcm.googleapis.com/fcm/send",
    method: :post,
    body: {
      "notification":{
        "title": self.title,
        "body": self.notif,
        "click_action": "FLUTTER_NOTIFICATION_CLICK"
      },
      "data": {
        "notif_id": self.id
      },
      "registration_ids":  device_tokens
    }.to_json,
    headers: { "Content-Type": "application/json", Authorization: "key=AAAAcJFAICc:APA91bGn2J0M1_e4ipdllUBjrA3bK4xxe3_R3Sz0QpvYBVu8emz-CJdqZQN9AxvKJyvMk7CTE8BUTvZPs12titKcMeixaSDFKLgCGv8Zed9B_x2r3CJgD5HR2MbciBsDR28BP_7000rs" }
  )
  request.run
  end

  
end
