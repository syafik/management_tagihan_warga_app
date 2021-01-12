Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'), 5, 104857600)

if caller.last =~ /script\/delayed_job/ or (File.basename($0) == "rake" and ARGV[0] =~ /jobs\:work/)
  ActiveRecord::Base.logger = Delayed::Worker.logger
end