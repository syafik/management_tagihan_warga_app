# frozen_string_literal: true

# == Schema Information
#
# Table name: user_contributions
#
#  id                        :bigint           not null, primary key
#  blok                      :string
#  contribution              :float
#  description               :text
#  expected_contribution     :decimal(10, 2)
#  imported_cash_transaction :boolean          default(FALSE)
#  month                     :integer
#  pay_at                    :date
#  payment_type              :integer
#  year                      :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  address_id                :integer
#  receiver_id               :integer
#
# Indexes
#
#  index_user_contributions_on_address_id             (address_id)
#  index_user_contributions_on_expected_contribution  (expected_contribution)
#  index_user_contributions_on_pay_at                 (pay_at)
#  index_user_contributions_on_year_and_month         (year,month)
#
require 'test_helper'

class UserContributionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
