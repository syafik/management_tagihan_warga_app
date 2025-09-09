# frozen_string_literal: true

# Address-specific contribution rates for special cases
class AddressContribution < ApplicationRecord
  belongs_to :address

  validates :amount, :effective_from, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :effective_until_after_effective_from
  validate :no_overlapping_periods

  # Scope to get active contribution rate for a specific date
  scope :active_on, ->(date) do
    where('effective_from <= ? AND (effective_until IS NULL OR effective_until >= ?)', date, date)
      .where(active: true)
      .order(effective_from: :desc)
  end

  # Additional scopes for ActiveAdmin
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :current, -> { where('effective_from <= ? AND (effective_until IS NULL OR effective_until >= ?)', Date.current, Date.current) }
  scope :future, -> { where('effective_from > ?', Date.current) }
  scope :expired, -> { where('effective_until < ?', Date.current) }
  scope :indefinite, -> { where(effective_until: nil) }

  # Get the contribution rate for an address on a specific date
  def self.rate_for_address_on_date(address_id, date = Date.current)
    where(address_id: address_id)
      .active_on(date)
      .first&.amount
  end

  # Check if this rate is currently active
  def active_on_date?(date = Date.current)
    active? &&
      effective_from <= date &&
      (effective_until.nil? || effective_until >= date)
  end

  # Check if rate is indefinite (no end date)
  def indefinite?
    effective_until.nil?
  end

  private

  def effective_until_after_effective_from
    return unless effective_until && effective_from

    errors.add(:effective_until, 'must be after effective_from') if effective_until <= effective_from
  end

  def no_overlapping_periods
    return unless address_id && effective_from

    overlapping = AddressContribution.where(address_id: address_id, active: true)
                                    .where.not(id: id)

    overlapping.each do |other|
      if periods_overlap?(effective_from, effective_until, other.effective_from, other.effective_until)
        errors.add(:base, 'Period overlaps with existing address contribution')
        break
      end
    end
  end

  def periods_overlap?(start1, end1, start2, end2)
    # Convert nil end dates to far future for comparison
    end1 = end1 || Date.new(9999, 12, 31)
    end2 = end2 || Date.new(9999, 12, 31)

    start1 <= end2 && start2 <= end1
  end
end