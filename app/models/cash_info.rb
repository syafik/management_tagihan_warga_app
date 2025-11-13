# == Schema Information
#
# Table name: cash_infos
#
#  id         :bigint           not null, primary key
#  remaining  :float
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class CashInfo < ApplicationRecord
end
