# == Schema Information
#
# Table name: settings
#
#  id          :bigint           not null, primary key
#  description :text
#  key         :string           not null
#  value       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_settings_on_key  (key) UNIQUE
#
require 'rails_helper'

RSpec.describe Setting, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
