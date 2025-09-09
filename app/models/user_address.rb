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
