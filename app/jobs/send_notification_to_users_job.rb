class SendNotificationToUsersJob < ApplicationJob
  queue_as :default

  def perform(notification_id, type, user_ids)
    user_notifications = []
    if type == 1
      User.select('id').all.each do |user|
        user_notifications << UserNotification.new(notification_id: notification_id, user_id: user.id)
      end
    elsif type == 2
      user_ids.each do |user_id|
        user_notifications << UserNotification.new(notification_id: notification_id, user_id: user_id)
      end
    end
    UserNotification.import user_notifications
    

    notification = Notification.find(notification_id)
    device_tokens = notification.app_notif_receivers.pluck(:device_token)
    request = Typhoeus::Request.new(
      "https://fcm.googleapis.com/fcm/send",
      method: :post,
      body: {
        "notification":{
          "title": notification.title,
          "body": notification.notif,
          "click_action": "FLUTTER_NOTIFICATION_CLICK"
        },
        "data": {
          "notif_id": notification.id
        },
        "registration_ids":  device_tokens
      }.to_json,
      headers: { "Content-Type": "application/json", Authorization: "key=#{ENV['FCM_APIKEY']}" }
    )
    request.run

  end
end
