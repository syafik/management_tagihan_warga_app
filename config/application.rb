# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SwitchupAdministrator
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
    config.autoload_paths += %W["#{Rails.root}/app/validators/"]
    config.autoload_paths += %W(#{Rails.root}/app/models/ckeditor) 

    config.time_zone = 'Jakarta'
    config.i18n.default_locale = :id
    config.active_job.queue_adapter = :delayed_job
  end
end
