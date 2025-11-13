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
require 'test_helper'

class AppSettingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
