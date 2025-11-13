# == Schema Information
#
# Table name: app_settings
#
#  id               :bigint           not null, primary key
#  home_page_text   :text
#  starting_balance :decimal(15, 2)   default(0.0)
#  starting_year    :integer          default(2025)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class AppSetting < ApplicationRecord
  validates :starting_balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :starting_year, presence: true, numericality: { greater_than: 2020, less_than: 2050 }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "home_page_text", "id", "updated_at", "starting_balance", "starting_year"]
  end

  def self.current_setting
    first_or_create(
      home_page_text: "Selamat datang di Sistem Manajemen PuriAyana",
      starting_balance: 0,
      starting_year: 2025
    )
  end

  def self.starting_balance
    current_setting.starting_balance || 0
  end

  def self.starting_year
    current_setting.starting_year || 2025
  end

  def self.home_page_text
    current_setting.home_page_text || "Selamat datang di Sistem Manajemen PuriAyana"
  end
end
