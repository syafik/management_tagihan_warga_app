require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    addresses: Field::HasMany,
    allow_password_change: Field::Boolean,
    debts: Field::HasMany,
    device_token: Field::String,
    device_type: Field::String,
    email: Field::String,
    encrypted_password: Field::String,
    login_code: Field::String,
    login_code_expires_at: Field::DateTime,
    name: Field::String,
    notifications: Field::HasMany,
    phone_number: Field::String,
    pic_blok: Field::String,
    primary_address: Field::HasOne,
    primary_address_relation: Field::HasOne,
    provider: Field::String,
    remember_created_at: Field::DateTime,
    reset_password_sent_at: Field::DateTime,
    reset_password_token: Field::String,
    role: Field::Number,
    tokens: Field::String.with_options(searchable: false),
    uid: Field::String,
    user_addresses: Field::HasMany,
    user_notifications: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    email
    phone_number
    role
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    email
    phone_number
    role
    addresses
    debts
    notifications
    user_addresses
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    email
    phone_number
    role
    encrypted_password
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  def display_resource(user)
    "#{user.name} (#{user.email})"
  end
end
