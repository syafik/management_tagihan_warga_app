class ClearExpiredNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    puts 'perform clear expired notification'
    Notification.clear_expired_notifications
    ClearExpiredNotificationsJob.set(wait_until: Date.tomorrow.midnight).perform_later
    puts 'end clear expired notification'
  end
end
