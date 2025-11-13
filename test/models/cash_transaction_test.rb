# frozen_string_literal: true

# == Schema Information
#
# Table name: cash_transactions
#
#  id                :bigint           not null, primary key
#  description       :text
#  month             :integer
#  total             :float
#  transaction_date  :date
#  transaction_group :integer
#  transaction_type  :integer
#  year              :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  pic_id            :integer
#
# Indexes
#
#  index_cash_transactions_on_month_and_year    (month,year)
#  index_cash_transactions_on_pic_id            (pic_id)
#  index_cash_transactions_on_transaction_date  (transaction_date)
#
require 'test_helper'

class CashTransactionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
