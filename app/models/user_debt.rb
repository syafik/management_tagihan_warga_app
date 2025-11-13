# frozen_string_literal: true

# == Schema Information
#
# Table name: user_debts
#
#  id         :bigint           not null, primary key
#  owed       :float
#  paid       :float
#  paid_off   :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  index_user_debts_on_user_id  (user_id)
#
class UserDebt < ApplicationRecord
end
