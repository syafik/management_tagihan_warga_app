# frozen_string_literal: true

# == Schema Information
#
# Table name: debts
#
#  id          :bigint           not null, primary key
#  debt_date   :date
#  debt_type   :integer
#  description :text
#  value       :float
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer
#
require 'test_helper'

class DebtTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
