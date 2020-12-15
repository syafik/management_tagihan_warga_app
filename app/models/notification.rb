# frozen_string_literal: true

class Notification < ApplicationRecord
  def self.ransack_predicates
    [
      %w[Contains cont],
      %w[Equal eq]
    ]
  end
end
