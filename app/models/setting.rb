class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  # Get setting value by key
  def self.get(key, default = nil)
    find_by(key: key)&.value || default
  end

  # Set or update setting value
  def self.set(key, value, description = nil)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.description = description if description.present?
    setting.save!
    setting
  end

  # Get arrears threshold in months
  def self.arrears_threshold_months
    get('arrears_threshold_months', '3').to_i
  end
end
