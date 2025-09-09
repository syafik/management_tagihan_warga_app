class Contribution < ApplicationRecord
  validates :amount, :effective_from, presence: true
  validates :amount, numericality: { greater_than: 0 }

  # Scope to get active contribution rate for a specific date
  scope :active_on, ->(date) { where('effective_from <= ?', date).order(effective_from: :desc) }

  # Additional scopes for ActiveAdmin
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :global, -> { where(block: nil) }
  scope :block_specific, -> { where.not(block: nil) }

  # Get the contribution rate effective on a specific date for a block
  def self.rate_for_block_on_date(block = nil, date = Date.current)
    query = active_on(date)
    query = query.where(block:) if block.present?
    query.first&.amount || 0
  end

  # Get current active rate for a block
  def self.current_rate_for_block(block = nil)
    rate_for_block_on_date(block, Date.current)
  end

  # Check if this contribution rate is currently active
  def active?
    effective_from <= Date.current
  end

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[amount effective_from block description active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
