# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  allow_manage_expense   :boolean          default(TRUE)
#  allow_manage_transfer  :boolean          default(TRUE)
#  allow_password_change  :boolean          default(FALSE), not null
#  device_token           :string
#  device_type            :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  login_code             :string
#  login_code_expires_at  :datetime
#  name                   :string           not null
#  phone_number           :string
#  pic_blok               :string
#  provider               :string           default("email"), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default(1), not null
#  tokens                 :json
#  uid                    :string           default(""), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable
  include DeviseTokenAuth::Concerns::User

  # Override Devise's email validation to make it optional
  validates :email, uniqueness: { allow_blank: true, case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  validates :name, :phone_number, presence: true
  validate :password_complexity
  validate :phone_number_format_validation

  # New many-to-many relationship with addresses
  has_many :user_addresses, dependent: :destroy
  has_many :addresses, through: :user_addresses
  has_one :primary_address_relation, -> { where(primary: true) }, class_name: 'UserAddress'
  has_one :primary_address, through: :primary_address_relation, source: :address
  before_validation :set_uid
  before_validation :normalize_phone_number
  before_validation :set_dummy_email_if_blank
  before_validation :set_random_password_if_blank, on: :create
  after_create :sync_address_ids

  has_one_attached :avatar
  has_many :debts

  has_many :user_notifications
  has_many :notifications, through: :user_notifications

  def set_uid
    self.uid = self.class.generate_uid if uid.blank?
  end

  def set_dummy_email_if_blank
    # Generate dummy email if email is blank
    # Use phone number as base to ensure uniqueness
    if email.blank? && phone_number.present?
      # Remove + and non-numeric characters from phone number
      clean_phone = phone_number.gsub(/[^\d]/, '')
      self.email = "user#{clean_phone}@dummy.local"
    end
  end

  def set_random_password_if_blank
    # Generate random password if password is blank on creation
    # Password format: 8 characters with at least 1 letter and 1 number
    if password.blank?
      # Generate random password: 6 letters + 2 numbers
      letters = ('a'..'z').to_a.sample(6).join
      numbers = ('0'..'9').to_a.sample(2).join
      random_password = (letters + numbers).chars.shuffle.join

      self.password = random_password
      self.password_confirmation = random_password

      Rails.logger.info "Generated random password for user with phone: #{phone_number}"
    end
  end

  def self.generate_uid
    loop do
      token = Devise.friendly_token
      break token unless to_adapter.find_first({ uid: token })
    end
  end

  def self.generate_reset_password_token_for(user)
    loop do
      token = ('0'..'9').to_a.sample(5).join
      user.reset_password_token = token
      user.reset_password_sent_at = Time.current
      break token if user.save
    end
  end

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

  def password_complexity
    # Regexp extracted from https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a
    return if password.blank? || password =~ /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$/

    errors.add :password, 'harus 8-128 karakter dan mempunyai minmal 1 number and 1 huruf.'
  end

  def normalize_phone_number
    return if phone_number.blank?

    # Remove all characters except + and digits
    cleaned = phone_number.gsub(/[^\d+]/, '')

    # Convert Indonesian format to international format
    if cleaned.match?(/^0\d+/)
      # 081234567890 -> +6281234567890
      self.phone_number = "+62#{cleaned[1..-1]}"
    elsif cleaned.match?(/^8\d+/)
      # 81234567890 -> +6281234567890
      self.phone_number = "+62#{cleaned}"
    elsif cleaned.match?(/^62\d+/)
      # 6281234567890 -> +6281234567890
      self.phone_number = "+#{cleaned}"
    elsif cleaned.start_with?('+')
      # Already has +, just use it
      self.phone_number = cleaned
    else
      # Unknown format, assume it needs +62
      self.phone_number = "+62#{cleaned}"
    end
  end

  def phone_number_format_validation
    return if phone_number.blank?

    # Only allow + and digits
    unless phone_number.match?(/^\+\d+$/)
      errors.add :phone_number, 'hanya boleh berisi + dan angka (contoh: +6281234567890)'
      return
    end

    # Must start with +62 for Indonesian numbers
    unless phone_number.start_with?('+62')
      errors.add :phone_number, 'harus diawali dengan +62 untuk nomor Indonesia'
    end

    # Minimum length check (e.g., +62812345678 = 13 characters minimum)
    if phone_number.length < 13
      errors.add :phone_number, 'terlalu pendek (minimal 10-11 digit setelah +62)'
    end
  end

  def is_admin?
    role == 2
  end

  def is_security?
    role == 3
  end

  def is_warga?
    role == 1
  end

  def role_name
    case role
    when 1
      'Warga'
    when 2
      'Admin'
    when 3
      'Sekuriti'
    end
  end

  validate :password_complexity

  def self.ransackable_attributes(_auth_object = nil)
    %w[email name addresses_block_address role]
  end

  # Check if user is head of family at any address
  def head_of_family?
    user_addresses.where(kk: true).exists?
  end

  # Check if user is head of family at specific address
  def head_of_family_at?(address)
    user_addresses.where(address:, kk: true).exists?
  end

  # Check if user can be warga (resident)
  def can_be_warga?
    is_warga? && addresses.present?
  end

  # Get primary address or first address
  def address
    primary_address || addresses.first
  end

  # Add user to an address (with optional primary and kk flags)
  def add_address!(address, primary: false, kk: false)
    user_address = user_addresses.find_or_create_by(address:)
    user_address.set_as_primary! if primary
    user_address.set_as_head_of_family! if kk
    user_address
  end

  # Remove user from an address
  def remove_address!(address)
    user_addresses.where(address:).destroy_all
  end

  # Virtual attribute for forms - sets the primary address
  def address_id=(address_id)
    return if address_id.blank?

    # Clear existing primary address
    user_addresses.where(primary: true).update_all(primary: false)

    # Find or create the new primary address relationship
    address = Address.find(address_id)
    add_address!(address, primary: true)
  end

  def address_id
    primary_address&.id
  end

  # Virtual attribute for handling multiple addresses from form
  def address_ids=(ids)
    # Store the IDs to be synced after create
    @pending_address_ids = ids

    # Return early if no IDs provided or all blank
    return if ids.blank?

    # Only sync if user is already persisted (for updates)
    return unless persisted?

    # Get valid address IDs, removing blank values
    valid_ids = ids.is_a?(Array) ? ids.reject(&:blank?).map(&:to_i) : [ids.to_i]

    # If no valid IDs, clear all addresses
    if valid_ids.empty?
      user_addresses.destroy_all
      return
    end

    # Remove addresses that are not in the new list
    user_addresses.where.not(address_id: valid_ids).destroy_all

    # Add new addresses
    valid_ids.each_with_index do |address_id, index|
      user_address = user_addresses.find_or_initialize_by(address_id: address_id)
      # Set first address as primary if no primary exists
      if index == 0 && !user_addresses.exists?(primary: true)
        user_address.primary = true
      end
      user_address.save if user_address.new_record? || user_address.changed?
    end
  end

  def address_ids
    addresses.pluck(:id)
  end

  # WhatsApp Login Code Methods
  def generate_login_code!
    self.login_code = SecureRandom.random_number(100_000..999_999).to_s
    self.login_code_expires_at = 10.minutes.from_now
    save!
    login_code
  end

  def login_code_valid?(code)
    return false if login_code.blank? || login_code_expired?

    login_code == code
  end

  def login_code_expired?
    login_code_expires_at.blank? || login_code_expires_at < Time.current
  end

  def clear_login_code!
    self.login_code = nil
    self.login_code_expires_at = nil
    save!
  end

  def send_login_code!
    code = generate_login_code!

    if Rails.env.production?
      # Queue the WhatsApp sending job
      SendWhatsappLoginCodeJob.perform_later(phone_number, code)
      Rails.logger.info "Queued WhatsApp login code job for #{phone_number}"
      result = { success: true, message: 'Login code queued for sending' }
    else
      # In development/test environments, just log the code
      Rails.logger.info "WhatsApp login code for #{phone_number}: #{code} (not sent - not in production)"
      result = { success: true, message: 'Code generated (not sent in non-production environment)' }
    end

    result
  end

  def send_invitation_notification!(address)
    if Rails.env.production?
      # Queue the invitation notification job
      SendInvitationNotificationJob.perform_later(id, address.id)
      Rails.logger.info "Queued invitation notification job for #{phone_number}"
      result = { success: true, message: 'Invitation notification queued for sending' }
    else
      # In development/test environments, just log the invitation
      app_url = 'http://localhost:3100'
      Rails.logger.info "WhatsApp invitation for #{phone_number}: Access granted to #{address.block_address} at #{app_url} (not sent - not in production)"
      result = { success: true, message: 'Invitation generated (not sent in non-production environment)' }
    end

    result
  end

  def self.find_by_phone(phone_number)
    # Normalize phone number for search
    normalized = normalize_phone_number(phone_number)
    where(phone_number: normalized).first
  end

  private

  def self.ransortable_attributes(_auth_object = nil)
    column_names
  end

  def deliver_reset_password_token_email(token)
    api_instance = SibApiV3Sdk::TransactionalEmailsApi.new
    send_smtp_email = SibApiV3Sdk::SendSmtpEmail.new
    sender = SibApiV3Sdk::SendSmtpEmailSender.new(name: 'admin-puri-ayana', email: 'no-reply@puriayanagempol.com')
    send_smtp_email.subject = '[Puri Ayana App] - Ini reset password token anda!'
    send_smtp_email.to = [{ name:, email: }]
    send_smtp_email.sender = sender
    send_smtp_email.html_content = "<html>
    <head>
      <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
    </head>
    <body>
      <p>Hello #{name}!</p>
      <p>
      Ini adalah token untuk mereset password Anda. Token ini berlaku selama 5 menit saja.<br>
      --------------------------
      </p>
      <p>Token Anda: <b>#{token}</b></p>
      <br>
      ----------
      </p>
      <p>
        Terima Kasih dan Selamat beraktifitas.
        Semoga Anda senantiasa sehat dan diberikan kemurahan rejeki, Aamiin..

        Salam, <br />
        Pengurus
      </p>
    </body>
  </html>
  "
    begin
      result = api_instance.send_transac_email(send_smtp_email)
      p result
    rescue SibApiV3Sdk::ApiError => e
      puts "Exception when calling TransactionalEmailsApi->send_transac_email: #{e}"
    end
  end

  def has_debt?
    return false unless debts.exists?

    debts.select { |d| d.debt_type == 1 }.sum(&:value) > debts.select { |d| d.debt_type == 2 }.sum(&:value)
  end

  def blok_name
    address.try(:block_address)
  end

  # Override Devise methods to make email optional
  def email_required?
    false
  end

  def email_changed?
    false
  end

  def will_save_change_to_email?
    false
  end

  # Sync address_ids after user is created
  def sync_address_ids
    return if @pending_address_ids.blank?

    # Get valid address IDs, removing blank values
    valid_ids = @pending_address_ids.is_a?(Array) ? @pending_address_ids.reject(&:blank?).map(&:to_i) : [@pending_address_ids.to_i]
    return if valid_ids.empty?

    # Add addresses
    valid_ids.each_with_index do |address_id, index|
      user_address = user_addresses.create(address_id: address_id)
      # Set first address as primary
      user_address.update(primary: true) if index == 0
    end

    @pending_address_ids = nil
  end

  class << self
    private

    def normalize_phone_number(phone)
      return nil unless phone

      # Remove all non-digit characters except +
      cleaned = phone.gsub(/[^\d+]/, '')

      # Add +62 for Indonesian numbers if no country code
      if cleaned.match(/^0\d+/)
        cleaned = "+62#{cleaned[1..-1]}"
      elsif cleaned.match(/^8\d+/)
        cleaned = "+62#{cleaned}"
      elsif !cleaned.start_with?('+')
        cleaned = "+62#{cleaned}"
      end

      cleaned
    end
  end
end
