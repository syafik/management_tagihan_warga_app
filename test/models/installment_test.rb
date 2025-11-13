# frozen_string_literal: true

# == Schema Information
#
# Table name: installments
#
#  id               :bigint           not null, primary key
#  description      :text
#  paid_off         :boolean          default(FALSE)
#  transaction_type :integer
#  value            :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :integer
#
# Indexes
#
#  index_installments_on_parent_id  (parent_id)
#
require 'test_helper'

class InstallmentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
