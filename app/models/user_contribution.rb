# frozen_string_literal: true

# == Schema Information
#
# Table name: user_contributions
#
#  id                        :bigint           not null, primary key
#  blok                      :string
#  contribution              :float
#  description               :text
#  expected_contribution     :decimal(10, 2)
#  imported_cash_transaction :boolean          default(FALSE)
#  month                     :integer
#  pay_at                    :date
#  payment_type              :integer
#  year                      :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  address_id                :integer
#  receiver_id               :integer
#
# Indexes
#
#  index_user_contributions_on_address_id             (address_id)
#  index_user_contributions_on_expected_contribution  (expected_contribution)
#  index_user_contributions_on_pay_at                 (pay_at)
#  index_user_contributions_on_year_and_month         (year,month)
#
class UserContribution < ApplicationRecord
  belongs_to :address
  belongs_to :receiver, class_name: 'User'

  validates :contribution, :pay_at, :receiver_id, :payment_type, :blok, presence: true
  validates :address_id, uniqueness: { scope: %i[month year], message: 'sudah ada untuk bulan dan tahun ini' }

  before_save :set_blok_group
  # Removed after_create :send_payment_notification callback
  # Notification should be sent manually from controller/service when needed

  MONTHNAMES =
    {
      'Januari' => 1,
      'Februari' => 2,
      'Maret' => 3,
      'April' => 4,
      'Mei' => 5,
      'Juni' => 6,
      'Juli' => 7,
      'Agustus' => 8,
      'September' => 9,
      'Oktober' => 10,
      'November' => 11,
      'Desember' => 12
    }.freeze

  PAYMENT_TYPES = {
    'CASH' => 1,
    'TRANSFER' => 2,
    'QRIS' => 3
  }.freeze

  def self.import_existing_data(execute_month)
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    Address::BLOK_NAME.each do |key, value|
      receiver = User.where("pic_blok LIKE '%#{key}%'").first
      ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[value]
      (1..ws.num_rows).each do |row|
        block_address = ws[row, 2].strip
        contribution = ws[row, 3].strip
        tagihan = ws[row, 4].strip
        next unless row >= 3

        address = Address.where(block_address:).first
        next unless address

        1.upto(execute_month - tagihan.to_i) do |_i|
          UserContribution.create(
            year: 2020,
            address_id: address.id,
            contribution: contribution.gsub(/[^\d]/, '').to_f,
            receiver_id: receiver.try(:id),
            blok: key
          )
        end
      end
    end
  end

  def payment_type_name
    case payment_type
    when PAYMENT_TYPES['CASH']
      'CASH'
    when PAYMENT_TYPES['TRANSFER']
      'TRANSFER'
    when PAYMENT_TYPES['QRIS']
      'QRIS'
    else
      'UNKNOWN'
    end
  end

  def contribution_long_desc
    desc = "LUNAS DAN DI TERIMA OLEH #{try(:receiver).try(:name).try(:upcase)}"
    desc += " TANGGAL #{pay_at.strftime('%d %B %Y')}" unless pay_at.blank?
    desc += " SECARA #{payment_type_name}"
    desc
  end

  def contribution_desc
    if payment_type == PAYMENT_TYPES['CASH']
      "Pembayaran Iuran, #{payment_type_name} Diterima Oleh: #{try(:receiver).try(:name).try(:upcase)}"
    else
      "Pembayaran Iuran, #{payment_type_name}"
    end
  end

  def tgl_bayar
    pay_at.blank? ? '-' : pay_at.strftime('%d %B %Y')
  end

  # Send notification for this contribution (call manually when needed)
  def send_payment_notification
    # Queue the notification job to run in background
    SendPaymentNotificationJob.perform_later(id)
    Rails.logger.info "Queued payment notification job for UserContribution ##{id}"
  rescue StandardError => e
    # Log error but don't fail the payment creation
    Rails.logger.error "Failed to queue payment notification: #{e.message}"
  end

  private

  def set_blok_group
    blok = address.block_address.gsub(/[^A-Za-z]/, '').upcase
  end
end
