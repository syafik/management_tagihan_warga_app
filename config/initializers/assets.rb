# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Minimal asset pipeline configuration for gem compatibility
Rails.application.config.assets.precompile += %w[
  rails_admin_override.scss
]

# Skip problematic rails_admin SASS compilation in production
if Rails.env.production?
  Rails.application.config.assets.precompile -= %w[rails_admin/rails_admin.scss]
  Rails.application.config.assets.precompile -= %w[rails_admin/bootstrap.js]
end