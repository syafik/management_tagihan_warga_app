# frozen_string_literal: true

require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

require "capistrano/rbenv"
require "capistrano/bundler"
require "capistrano/puma"
require "capistrano/rails"

require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
# require 'capistrano/rails/db'
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require 'dotenv'
require 'capistrano/dotenv/tasks'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
Rake::Task[:production].invoke

