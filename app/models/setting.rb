# == Schema Information
#
# Table name: settings
#
#  id          :bigint           not null, primary key
#  description :text
#  key         :string           not null
#  value       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_settings_on_key  (key) UNIQUE
#
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
    get('arrears_threshold_months', '2').to_i
  end
end
