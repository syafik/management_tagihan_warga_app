# frozen_string_literal: true

namespace :solid_queue do
  desc 'Install Solid Queue systemd service'
  task :install do
    on roles(:app) do
      sudo :cp, release_path.join('config/systemd/solid_queue.service'), '/etc/systemd/system/'
      sudo :systemctl, 'daemon-reload'
      sudo :systemctl, 'enable', 'solid_queue'
      info 'Solid Queue systemd service installed and enabled'
    end
  end

  desc 'Start Solid Queue worker'
  task :start do
    on roles(:app) do
      sudo :systemctl, 'start', 'solid_queue'
      info 'Solid Queue worker started'
    end
  end

  desc 'Stop Solid Queue worker'
  task :stop do
    on roles(:app) do
      sudo :systemctl, 'stop', 'solid_queue'
      info 'Solid Queue worker stopped'
    end
  end

  desc 'Restart Solid Queue worker'
  task :restart do
    on roles(:app) do
      sudo :systemctl, 'restart', 'solid_queue'
      info 'Solid Queue worker restarted'
    end
  end

  desc 'Check Solid Queue worker status'
  task :status do
    on roles(:app) do
      sudo :systemctl, 'status', 'solid_queue'
    end
  end
end

# Auto-restart Solid Queue after deployment
after 'deploy:publishing', 'solid_queue:restart'
