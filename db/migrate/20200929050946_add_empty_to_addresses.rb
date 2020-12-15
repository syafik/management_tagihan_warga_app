# frozen_string_literal: true

class AddEmptyToAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :empty, :boolean, default: false
  end
end
