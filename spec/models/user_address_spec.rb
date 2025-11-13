# == Schema Information
#
# Table name: user_addresses
#
#  id         :bigint           not null, primary key
#  kk         :boolean          default(FALSE)
#  primary    :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  address_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_addresses_on_address_id              (address_id)
#  index_user_addresses_on_address_id_and_kk       (address_id,kk)
#  index_user_addresses_on_user_id                 (user_id)
#  index_user_addresses_on_user_id_and_address_id  (user_id,address_id) UNIQUE
#  index_user_addresses_on_user_id_and_primary     (user_id,primary)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe UserAddress, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
