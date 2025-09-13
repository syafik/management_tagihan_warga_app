# frozen_string_literal: true

class SampleJob < ApplicationJob
  queue_as :default

  def perform(message)
    Rails.logger.info "Sample job executed: #{message}"
    # You can add any background task here
    # For example: sending emails, processing files, etc.
  end
end