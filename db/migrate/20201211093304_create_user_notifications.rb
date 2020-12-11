class CreateUserNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :user_notifications do |t|
      t.integer :notification_id
      t.integer :user_id
      t.boolean :is_read, default: false

      t.timestamps
    end
    add_index :user_notifications, [:notification_id, :user_id]
  end
end
