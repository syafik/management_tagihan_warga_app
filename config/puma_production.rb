# config/puma_production.rb
# !/usr/bin/env puma

directory '/var/www/puriayana-app'
rackup '/var/www/puriayana-app/config.ru'
environment 'production'

pidfile '/var/www/puriayana-app/tmp/pids/puma.pid'
state_path '/var/www/puriayana-app/tmp/pids/puma.state'
stdout_redirect '/var/www/puriayana-app/log/puma.log',
                '/var/www/puriayana-app/log/puma_err.log', true

threads 2, 16
workers 2

bind 'unix:///var/www/puriayana-app/tmp/sockets/puma.sock'

preload_app!

on_restart do
  puts 'Refreshing Gemfile'
  ENV['BUNDLE_GEMFILE'] = '/var/www/puriayana-app/Gemfile'
end

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end
