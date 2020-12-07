class CreateAddresses < ActiveRecord::Migration[5.2]
  def change
    create_table :addresses do |t|
      t.string :block_address
      t.string :block_number
      t.string :block
      t.decimal :contribution, precision: 13, scale: 2
      t.integer :arrears, default: 0
      t.timestamps
    end
  end
end
