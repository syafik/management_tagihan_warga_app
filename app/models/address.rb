# frozen_string_literal: true

# storing address

class Address < ApplicationRecord
  has_many :users
  has_many :user_contributions, -> { order 'id asc' }
  has_one :main_user, -> {where(kk: true)}, class_name: 'User', foreign_key: 'address_id'

  validates :block_address, :contribution, presence: true
  validates_uniqueness_of :block_address
  validates_numericality_of :contribution

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
    tagihan = total_paid_should_be - total_paid)
    tagihan = 0 if tagihan < 0
    tagihan
  end

end
