# frozen_string_literal: true

# == Schema Information
#
# Table name: total_contributions
#
#  id         :bigint           not null, primary key
#  blok       :string
#  month      :integer
#  total      :float
#  year       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_total_contributions_on_month_and_year_and_blok  (month,year,blok)
#
require 'test_helper'

class TotalContributionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
