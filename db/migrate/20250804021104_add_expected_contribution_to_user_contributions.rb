# frozen_string_literal: true

# Add expected_contribution column to track what should have been paid vs what was actually paid
class AddExpectedContributionToUserContributions < ActiveRecord::Migration[7.0]
  def change
    add_column :user_contributions, :expected_contribution, :decimal, precision: 10, scale: 2
    add_index :user_contributions, :expected_contribution
  end
end