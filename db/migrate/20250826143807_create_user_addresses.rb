class CreateUserAddresses < ActiveRecord::Migration[7.0]
  def change
    create_table :user_addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.boolean :primary, default: false
      t.boolean :kk, default: false # head of family flag moved from users table

      t.timestamps
    end

    # Add indexes
    add_index :user_addresses, [:user_id, :address_id], unique: true
    add_index :user_addresses, [:user_id, :primary]
    add_index :user_addresses, [:address_id, :kk]
    
    # Migrate existing data from users table
    reversible do |dir|
      dir.up do
        # Copy existing user-address relationships
        execute <<-SQL
          INSERT INTO user_addresses (user_id, address_id, "primary", kk, created_at, updated_at)
          SELECT id, address_id, true, kk, created_at, updated_at
          FROM users 
          WHERE address_id IS NOT NULL
        SQL
      end
    end
  end
end
