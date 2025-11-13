# == Schema Information
#
# Table name: template_transactions
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE)
#  amount            :float
#  description       :text
#  transaction_group :integer
#  transaction_type  :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require 'rails_helper'

RSpec.describe TemplateTransaction, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
