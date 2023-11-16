# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.2.2"

gem "rails", "~> 7.0.0"

# Use postgresql as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma'
# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
gem 'dotenv-rails'
gem 'activerecord-import'
gem 'brakeman'
gem 'ckeditor', github: 'galetahub/ckeditor'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'devise'
gem 'devise_token_auth'
# if you haven't added it, already
gem 'google_drive'
gem 'kaminari'
gem 'paperclip'
gem 'pdfkit'
gem 'ransack'
gem 'rubocop'
gem 'sib-api-v3-sdk'
gem "typhoeus"
gem 'wkhtmltopdf-binary'
gem 'swagger-docs'

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
  gem 'listen', '~> 3.0.5'
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
