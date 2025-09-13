# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Minimal asset pipeline configuration for gem compatibility (CKEditor, etc.)
Rails.application.config.assets.precompile += %w[
  delayed_job_web/application.css
  delayed_job_web/application.js
]