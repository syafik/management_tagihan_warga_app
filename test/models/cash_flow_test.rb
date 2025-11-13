# frozen_string_literal: true

# == Schema Information
#
# Table name: cash_flows
#
#  id         :bigint           not null, primary key
#  cash_in    :float
#  cash_out   :float
#  month      :integer
#  total      :float
#  year       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_cash_flows_on_month_and_year  (month,year)
#
require 'test_helper'

class CashFlowTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
