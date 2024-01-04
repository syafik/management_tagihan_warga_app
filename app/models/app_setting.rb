class AppSetting < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "home_page_text", "id", "updated_at"]
  end
end
