# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable
  include DeviseTokenAuth::Concerns::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, :phone_number, presence: true
  validate :password_complexity
  validate :phone_number_format_validation

  belongs_to :address, optional: true
  before_validation :set_uid

  has_one_attached :avatar
  has_many :debts

  has_many :user_notifications
  has_many :notifications, through: :user_notifications

  def set_uid
    self.uid = self.class.generate_uid if uid.blank?
  end

  def self.generate_uid
    loop do
      token = Devise.friendly_token
      break token unless to_adapter.find_first({ uid: token })
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

  def phone_number_format_validation
    return if phone_number.blank? || phone_number =~ /\+?([ -]?\d+)+|\(\d+\)([ -]\d+)/

    errors.add :phone_number, 'harus diisi dengan format yang benar.'
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

  def self.ransortable_attributes(_auth_object = nil)
    column_names
  end

  def deliver_reset_password_token_email(token)
    api_instance = SibApiV3Sdk::TransactionalEmailsApi.new
    send_smtp_email = SibApiV3Sdk::SendSmtpEmail.new
    sender = SibApiV3Sdk::SendSmtpEmailSender.new(name: 'admin-puri-ayana', email: 'no-reply@puriayanagempol.com')
    send_smtp_email.subject = '[Puri Ayana App] - Ini reset password token anda!'
    send_smtp_email.to = [{name: name, email: email}]
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
    debts.select{|d| d.debt_type == 1}.sum(&:value) > debts.select{|d| d.debt_type == 2}.sum(&:value) 
  end

  def blok_name
    address.try(:block_address)
  end

end
