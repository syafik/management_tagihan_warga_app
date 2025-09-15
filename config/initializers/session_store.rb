# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Rails 8 session store configuration
Rails.application.config.session_store :cookie_store, 
  key: '_puriayana_session',
  httponly: true,
  secure: Rails.env.production?
