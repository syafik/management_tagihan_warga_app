# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Minimal asset pipeline configuration for gem compatibility (CKEditor, etc.)
# Add all CSS and JS files to ensure mounted engines work
Rails.application.config.assets.precompile += %w( *.css *.js )