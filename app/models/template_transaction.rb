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
class TemplateTransaction < ApplicationRecord
end
