# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encounter a DeadlockRetry::Deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
  
  # Set default queue name
  queue_as :default
  
  # Set default retry attempts
  retry_on StandardError, wait: 5.seconds, attempts: 3
end
