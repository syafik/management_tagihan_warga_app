# frozen_string_literal: true

# storing address

class Address < ApplicationRecord
  # New many-to-many relationship with users
  has_many :user_addresses, dependent: :destroy
  has_many :users, through: :user_addresses
  has_many :residents, -> { where(role: 1) }, through: :user_addresses, source: :user # Warga only
  has_one :head_of_family_relation, -> { where(kk: true) }, class_name: 'UserAddress'
  has_one :head_of_family, through: :head_of_family_relation, source: :user
  has_many :user_contributions, -> { order 'id desc' }
  has_one :latest_contribution, -> { order 'id desc' }, class_name: 'UserContribution'
  has_many :address_contributions, -> { order 'effective_from desc' }

  validates :block_address, presence: true
  validates_uniqueness_of :block_address

  BLOK_NAME = {
    'A' => 0,
    'B' => 1,
    'C' => 2,
    'D' => 3,
    'F' => 4
  }.freeze

  def self.ransack_predicates
    [
      %w[Contains cont],
      ['Not Contains', 'not_cont'],
      %w[Equal eq],
      ['Not Equal', 'not_eq'],
      ['Less Than', 'lt'],
      ['Less Than or Equal to', 'lteq'],
      ['Greater Than', 'gt'],
      ['Greater Than or Equal to', 'gteq']
    ]
  end

  def tagihan_now
    total_paid = user_contributions.count
    total_paid_should_be = (Date.current.year.to_i - 2020) * 12 + Date.current.month.to_i
    tagihan = total_paid_should_be - total_paid
    tagihan = 0 if tagihan < 0
    tagihan
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[arrears block block_address block_number created_at empty id updated_at]
  end

  # Get the block letter from block_address (e.g., "A12" -> "A")
  def block_letter
    block_address.gsub(/[^A-Za-z]/, '').upcase.first
  end

  # Get current contribution rate for this address (with hierarchy)
  def current_contribution_rate
    contribution_rate_on_date(Date.current)
  end

  # Get contribution rate for a specific date (with hierarchy)
  def contribution_rate_on_date(date)
    # 1. Check for address-specific rate (highest priority)
    address_rate = AddressContribution.rate_for_address_on_date(id, date)
    return address_rate if address_rate

    # 2. Check for block-specific rate
    block_rate = Contribution.rate_for_block_on_date(block_letter, date)
    return block_rate if block_rate&.positive?

    # 3. Fall back to global rate
    Contribution.rate_for_block_on_date(nil, date)
  end

  # Calculate expected contribution amount for a specific month/year
  def expected_contribution_for(month, year)
    date = Date.new(year, month, 1)
    contribution_rate_on_date(date)
  end

  # Check if address has any active special rates
  def special_rate?(date = Date.current)
    AddressContribution.rate_for_address_on_date(id, date).present?
  end

  # Get active special rate details
  def active_special_rate(date = Date.current)
    address_contributions.find { |ac| ac.active_on_date?(date) }
  end

  # Display name for admin interfaces
  def display_name
    block_address&.upcase || "Address ##{id}"
  end

  # Rails admin friendly display
  def to_s
    display_name
  end

  # Get all resident users (role = 1, warga)
  def resident_users
    users.where(role: 1)
  end

  # Get count of residents
  def residents_count
    resident_users.count
  end

  # Get head of family name
  def head_of_family_name
    head_of_family&.name || 'Tidak ada'
  end

  # Check if address has head of family
  def has_head_of_family?
    head_of_family.present?
  end

  # Add user to this address (with optional primary and kk flags)
  def add_user!(user, primary: false, kk: false)
    user_address = user_addresses.find_or_create_by(user: user)
    user_address.set_as_primary! if primary
    user_address.set_as_head_of_family! if kk
    user_address
  end

  # Remove user from this address
  def remove_user!(user)
    user_addresses.where(user: user).destroy_all
  end
end
