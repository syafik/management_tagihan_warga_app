# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.2.1"

gem "rails", "8.0.2"

# Use postgresql as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma'
# Use Vite as the asset bundler
gem 'vite_rails'

# Asset pipeline for compatibility with gems like CKEditor
gem 'sprockets-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.14'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
gem 'dotenv-rails'
gem 'activerecord-import'
gem 'brakeman'
gem 'solid_queue'
gem 'devise'
gem 'devise_token_auth', '~> 1.2.3'
# if you haven't added it, already
gem 'google_drive'
gem 'pagy'
# gem 'paperclip' # Not Rails 8 compatible, use image_processing instead
gem 'image_processing'
gem 'pdfkit'
gem 'ransack'
gem 'rubocop'
gem 'sib-api-v3-sdk'
gem "typhoeus"
gem 'httparty'
gem 'wkhtmltopdf-binary'
gem 'swagger-docs'
gem 'rails_admin' # Temporarily disabled due to SASS compilation issues
gem 'cancancan'
gem 'sass-rails'
gem 'coffee-rails'
gem "solid_queue_dashboard", "~> 0.2.0"
gem 'chartkick'

group :development, :test do
  # Call 'byebug' to stop execution and get a debugger console
  gem 'pry'
  gem 'pry-byebug'
  %w[rspec-core rspec-expectations rspec-mocks rspec-rails rspec-support].each do |lib|
    gem lib, git: "https://github.com/rspec/#{lib}.git", branch: 'main'
  end
end

group :test do
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'database_cleaner'
  gem 'simplecov', require: false
end

group :development do
  # Access an IRB console by using <%= console %> anywhere in the code.
  gem 'listen', '~> 3.9'
  gem 'web-console'
  # Spring speeds up development by keeping your application running in the background.
  # Read more: https://github.com/rails/spring
  gem 'capistrano', require: false
  gem 'capistrano3-puma'
  gem 'capistrano-dotenv-tasks', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rbenv', require: false
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files,
# so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
