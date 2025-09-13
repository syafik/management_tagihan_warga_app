# config/puma_production.rb
#!/usr/bin/env puma

directory '/home/deploy/management_tagihan_warga_app'
rackup '/home/deploy/management_tagihan_warga_app/config.ru'
environment 'production'

pidfile '/home/deploy/management_tagihan_warga_app/tmp/pids/puma.pid'
state_path '/home/deploy/management_tagihan_warga_app/tmp/pids/puma.state'
stdout_redirect '/home/deploy/management_tagihan_warga_app/log/puma.log', '/home/deploy/management_tagihan_warga_app/log/puma_err.log', true

threads 2, 16
workers 2

bind 'unix:///home/deploy/management_tagihan_warga_app/tmp/sockets/puma.sock'

preload_app!

on_restart do
  puts 'Refreshing Gemfile'
  ENV["BUNDLE_GEMFILE"] = '/home/deploy/management_tagihan_warga_app/Gemfile'
end

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end