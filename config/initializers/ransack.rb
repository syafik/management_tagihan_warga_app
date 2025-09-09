# frozen_string_literal: true

# Configure Ransack to allow all attributes and associations
# This restores the old behavior before the security changes
Ransack.configure do |config|
  # Allow all attributes to be searched by default
  config.add_predicate 'equals_any',
    arel_predicate: 'in',
    formatter: proc { |v| v.split(/,\s*/) },
    validator: proc { |v| v.present? },
    type: :string

  # Ignore the whitelist requirement for attributes and associations
  config.ignore_unknown_conditions = false
end

# Monkey patch to disable the ransackable restrictions
# This allows searching on all attributes and associations without explicit allowlisting
module Ransack
  module Adapters
    module ActiveRecord
      module Base
        def ransackable_attributes(auth_object = nil)
          column_names + _ransackers.keys
        end

        def ransackable_associations(auth_object = nil)
          reflect_on_all_associations.map { |a| a.name.to_s }
        end
      end
    end
  end
end