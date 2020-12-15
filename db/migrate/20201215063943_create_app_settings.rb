class CreateAppSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :app_settings do |t|
      t.text :home_page_text

      t.timestamps
    end
  end
end
