# Optimized Puma Configuration for Production
# !/usr/bin/env puma

directory '/var/www/puriayana-app'
rackup '/var/www/puriayana-app/config.ru'
environment 'production'

pidfile '/var/www/puriayana-app/tmp/pids/puma.pid'
state_path '/var/www/puriayana-app/tmp/pids/puma.state'
stdout_redirect '/var/www/puriayana-app/log/puma.log',
                '/var/www/puriayana-app/log/puma_err.log', true

# Optimized for better throughput
# Threads: min 5, max 16 (optimized for 2GB RAM)
threads 5, 16

# Workers: 2 processes (perfect for 2 CPU cores)
workers 2

# Socket configuration
bind 'unix:///var/www/puriayana-app/tmp/sockets/puma.sock?backlog=1024'

# Performance optimizations
preload_app!
plugin :tmp_restart

# Memory management
worker_timeout 60
worker_boot_timeout 60
worker_shutdown_timeout 30

# Restart workers after serving requests (prevents memory leaks)
worker_culling_strategy :oldest
max_ram 1536 # MB (leave 512MB for system)

on_restart do
  puts 'Refreshing Gemfile'
  ENV['BUNDLE_GEMFILE'] = '/var/www/puriayana-app/Gemfile'
end

on_worker_boot do
  # Establish DB connection per worker
  ActiveSupport.on_load(:active_record) do
    config = ActiveRecord::Base.configurations[Rails.env] ||
             Rails.application.config.database_configuration[Rails.env]
    config['pool'] = 20
    ActiveRecord::Base.establish_connection(config)
  end
end

# Graceful shutdown
on_worker_shutdown do
  puts "Worker #{Process.pid} shutting down"
end
