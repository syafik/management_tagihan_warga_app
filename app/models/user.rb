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

    def set_uid
      self.uid = self.class.generate_uid if self.uid.blank?
    end

    def self.generate_uid
      loop do
        token = Devise.friendly_token
        break token unless to_adapter.find_first({ uid: token })
      end
    end


  def self.ransack_predicates
    [
        ["Contains", 'cont'],
        ["Not Contains", 'not_cont'],
        ["Equal", 'eq'],
        ["Not Equal", 'not_eq'],
        ["Less Than", 'lt'],
        ["Less Than or Equal to", 'lteq'],
        ["Greater Than", 'gt'],
        ["Greater Than or Equal to", 'gteq']
    ]
  end

  def password_complexity
    # Regexp extracted from https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a
    if password.blank? || password =~ /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$/
      return
    end

    errors.add :password, 'harus 8-128 karakter dan mempunyai minmal 1 number and 1 huruf.'
  end
  
  def phone_number_format_validation
    if phone_number.blank? || phone_number =~ /\+?([ -]?\d+)+|\(\d+\)([ -]\d+)/
      return
    end
    errors.add :phone_number, 'harus diisi dengan format yang benar.'
  end

  def is_admin?
    self.role == 2
  end

  def is_security?
    self.role == 3
  end

  def is_warga?
    self.role == 1
  end

  def role_name
    case self.role
    when 1
      "Warga"
    when 2
      "Admin"
    when 3
      "Sekuriti"
    end
  end


  validate :password_complexity

  def self.ransackable_attributes(auth_object = nil)
    %w(email name addresses_block_address role)
  end

  def self.ransortable_attributes(_auth_object = nil)
    column_names
  end

end
