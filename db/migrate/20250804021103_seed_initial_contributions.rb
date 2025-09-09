class SeedInitialContributions < ActiveRecord::Migration[7.0]
  def up
    # Migrate existing contribution rates from addresses table to contributions table
    # Get unique contribution amounts from addresses
    contribution_rates = Address.distinct.pluck(:contribution).compact.reject(&:zero?)

    contribution_rates.each do |rate|
      # Create a global contribution rate (applies to all blocks)
      # You can adjust this based on your business logic
      Contribution.create!(
        amount: rate,
        effective_from: Date.new(2020, 1, 1), # Adjust start date as needed
        description: 'Initial contribution rate migrated from addresses table',
        active: true
      )
    end

    # If you need block-specific rates, you can add them here
    # Example:
    # Contribution.create!(
    #   amount: 50000,
    #   effective_from: Date.new(2025, 8, 1),
    #   block: 'A',
    #   description: "New rate for Block A starting August 2025",
    #   active: true
    # )
  end

  def down
    Contribution.delete_all
  end
end
