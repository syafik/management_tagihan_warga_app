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
class UserAddress < ApplicationRecord
  belongs_to :user
  belongs_to :address

  validates :user_id, presence: true
  validates :address_id, presence: true
  validates :user_id, uniqueness: { scope: :address_id }
  
  # Only one primary address per user
  validates :primary, uniqueness: { scope: :user_id }, if: :primary?
  
  # Only one head of family per address
  validates :kk, uniqueness: { scope: :address_id }, if: :kk?

  scope :primary, -> { where(primary: true) }
  scope :head_of_family, -> { where(kk: true) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_address, ->(address) { where(address: address) }

  # Set as primary address for user
  def set_as_primary!
    transaction do
      # Remove primary from other addresses for this user
      UserAddress.where(user: user).update_all(primary: false)
      update!(primary: true)
    end
  end

  # Set as head of family for address
  def set_as_head_of_family!
    transaction do
      # Remove kk from other users for this address
      UserAddress.where(address: address).update_all(kk: false)
      update!(kk: true)
    end
  end
end
