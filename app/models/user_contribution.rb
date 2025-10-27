# frozen_string_literal: true

class UserContribution < ApplicationRecord
  belongs_to :address
  belongs_to :receiver, class_name: 'User'

  validates :contribution, :pay_at, :receiver_id, :payment_type, :blok, presence: true

  before_save :set_blok_group
  after_create :send_payment_notification

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

  def contribution_long_desc
    desc = "LUNAS DAN DI TERIMA OLEH #{try(:receiver).try(:name).try(:upcase)}"
    desc += " TANGGAL #{pay_at.strftime('%d %B %Y')}" unless pay_at.blank?
    desc += " SECARA #{payment_type == 2 ? 'TRANSFER' : 'CASH'}"
    desc
  end

  def contribution_desc
    "Pembayaran Iuran, #{payment_type == 2 ? 'TRANSFER' : 'CASH'} Diterima Oleh: #{try(:receiver).try(:name).try(:upcase)}"
  end

  def tgl_bayar
    pay_at.blank? ? '-' : pay_at.strftime('%d %B %Y')
  end

  private

  def set_blok_group
    blok = address.block_address.gsub(/[^A-Za-z]/, '').upcase
  end

  def send_payment_notification
    # Queue the notification job to run in background
    SendPaymentNotificationJob.perform_later(id)
    Rails.logger.info "Queued payment notification job for UserContribution ##{id}"
  rescue StandardError => e
    # Log error but don't fail the payment creation
    Rails.logger.error "Failed to queue payment notification: #{e.message}"
  end
end
