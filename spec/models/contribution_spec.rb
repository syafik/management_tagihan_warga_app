# == Schema Information
#
# Table name: contributions
#
#  id             :bigint           not null, primary key
#  active         :boolean          default(TRUE)
#  amount         :decimal(10, 2)   not null
#  block          :string(1)
#  description    :text
#  effective_from :date             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_contributions_on_active                    (active)
#  index_contributions_on_block                     (block)
#  index_contributions_on_effective_from_and_block  (effective_from,block)
#
require 'rails_helper'

RSpec.describe Contribution, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
