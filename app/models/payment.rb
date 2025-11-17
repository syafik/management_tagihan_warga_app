class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :address

  STATUSES = %w[UNPAID PAID FAILED EXPIRED REFUND].freeze

  validates :reference, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :payment_method, presence: true

  scope :pending, -> { where(status: 'UNPAID') }
  scope :completed, -> { where(status: 'PAID') }
  scope :recent, -> { order(created_at: :desc) }

  def paid?
    status == 'PAID'
  end

  def pending?
    status == 'UNPAID'
  end

  def expired?
    status == 'EXPIRED' || (expired_at.present? && expired_at < Time.current)
  end

  def mark_as_paid!(paid_time = Time.current)
    update!(
      status: 'PAID',
      paid_at: paid_time
    )
  end

  def mark_as_failed!
    update!(status: 'FAILED')
  end

  def mark_as_expired!
    update!(status: 'EXPIRED')
  end

  def time_remaining
    return 0 if expired_at.nil? || expired?
    (expired_at - Time.current).to_i
  end
end
