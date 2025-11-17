require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:address) }
  end

  describe 'validations' do
    it { should validate_presence_of(:reference) }
    it { should validate_uniqueness_of(:reference) }
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:payment_method) }
    it { should validate_inclusion_of(:status).in_array(Payment::STATUSES) }
  end

  describe 'scopes' do
    let!(:pending_payment) { create(:payment, status: 'UNPAID') }
    let!(:completed_payment) { create(:payment, status: 'PAID') }

    it 'returns pending payments' do
      expect(Payment.pending).to include(pending_payment)
      expect(Payment.pending).not_to include(completed_payment)
    end

    it 'returns completed payments' do
      expect(Payment.completed).to include(completed_payment)
      expect(Payment.completed).not_to include(pending_payment)
    end
  end

  describe '#paid?' do
    it 'returns true for PAID status' do
      payment = build(:payment, status: 'PAID')
      expect(payment.paid?).to be true
    end

    it 'returns false for other statuses' do
      payment = build(:payment, status: 'UNPAID')
      expect(payment.paid?).to be false
    end
  end

  describe '#pending?' do
    it 'returns true for UNPAID status' do
      payment = build(:payment, status: 'UNPAID')
      expect(payment.pending?).to be true
    end
  end

  describe '#expired?' do
    it 'returns true when expired_at is in the past' do
      payment = build(:payment, expired_at: 1.hour.ago)
      expect(payment.expired?).to be true
    end

    it 'returns true when status is EXPIRED' do
      payment = build(:payment, status: 'EXPIRED')
      expect(payment.expired?).to be true
    end

    it 'returns false when expired_at is in the future' do
      payment = build(:payment, expired_at: 1.hour.from_now)
      expect(payment.expired?).to be false
    end
  end

  describe '#time_remaining' do
    it 'returns seconds until expiration' do
      payment = build(:payment, expired_at: 1.hour.from_now)
      expect(payment.time_remaining).to be_within(10).of(3600)
    end

    it 'returns 0 when expired' do
      payment = build(:payment, expired_at: 1.hour.ago)
      expect(payment.time_remaining).to eq(0)
    end
  end

  describe '#mark_as_paid!' do
    it 'updates status and paid_at' do
      payment = create(:payment, status: 'UNPAID')
      time = Time.current
      payment.mark_as_paid!(time)

      expect(payment.status).to eq('PAID')
      expect(payment.paid_at).to eq(time)
    end
  end
end
