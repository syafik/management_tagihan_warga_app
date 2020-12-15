# frozen_string_literal: true

class CreateTotalContributions < ActiveRecord::Migration[5.2]
  def change
    create_table :total_contributions do |t|
      t.integer :year
      t.integer :month
      t.string :blok
      t.float :total
      t.timestamps
    end
    add_index :total_contributions, %i[month year blok]
  end
end
