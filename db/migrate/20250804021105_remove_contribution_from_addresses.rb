# frozen_string_literal: true

# Remove contribution column from addresses as we now use contributions table
class RemoveContributionFromAddresses < ActiveRecord::Migration[7.0]
  def up
    remove_column :addresses, :contribution
  end

  def down
    add_column :addresses, :contribution, :float
  end
end