# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.session_store = :cookie_store
  config.session_options = { key: '_puriayana_session' }
end
