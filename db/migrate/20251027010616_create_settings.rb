class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :key, null: false
      t.string :value
      t.text :description

      t.timestamps
    end

    add_index :settings, :key, unique: true

    # Add default setting for arrears threshold
    reversible do |dir|
      dir.up do
        Setting.create!(
          key: 'arrears_threshold_months',
          value: '3',
          description: 'Minimum months of arrears to show in the arrears report'
        )
      end
    end
  end
end
