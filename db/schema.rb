# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_07_16_095707) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "block_address"
    t.string "block_number"
    t.string "block"
    t.decimal "contribution", precision: 13, scale: 2
    t.integer "arrears", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "empty", default: false
  end

  create_table "app_settings", force: :cascade do |t|
    t.text "home_page_text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "cash_flows", force: :cascade do |t|
    t.float "cash_in"
    t.float "cash_out"
    t.float "total"
    t.integer "month"
    t.integer "year"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["month", "year"], name: "index_cash_flows_on_month_and_year"
  end

  create_table "cash_infos", force: :cascade do |t|
    t.string "title"
    t.float "remaining"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "cash_transactions", force: :cascade do |t|
    t.date "transaction_date"
    t.integer "transaction_type"
    t.float "total"
    t.integer "month"
    t.integer "year"
    t.integer "transaction_group"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "pic_id"
    t.index ["month", "year"], name: "index_cash_transactions_on_month_and_year"
    t.index ["pic_id"], name: "index_cash_transactions_on_pic_id"
    t.index ["transaction_date"], name: "index_cash_transactions_on_transaction_date"
  end

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string "data_file_name", null: false
    t.string "data_content_type"
    t.integer "data_file_size"
    t.string "data_fingerprint"
    t.string "type", limit: 30
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["type"], name: "index_ckeditor_assets_on_type"
  end

  create_table "debts", force: :cascade do |t|
    t.integer "user_id"
    t.float "value"
    t.text "description"
    t.date "debt_date"
    t.integer "debt_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "installments", force: :cascade do |t|
    t.text "description"
    t.float "value"
    t.integer "transaction_type"
    t.integer "parent_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "paid_off", default: false
    t.index ["parent_id"], name: "index_installments_on_parent_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "title"
    t.text "notif"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "total_contributions", force: :cascade do |t|
    t.integer "year"
    t.integer "month"
    t.string "blok"
    t.float "total"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["month", "year", "blok"], name: "index_total_contributions_on_month_and_year_and_blok"
  end

  create_table "user_contributions", force: :cascade do |t|
    t.integer "year"
    t.integer "month"
    t.float "contribution"
    t.date "pay_at"
    t.integer "receiver_id"
    t.integer "payment_type"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "address_id"
    t.string "blok"
    t.boolean "imported_cash_transaction", default: false
    t.index ["address_id"], name: "index_user_contributions_on_address_id"
    t.index ["pay_at"], name: "index_user_contributions_on_pay_at"
    t.index ["year", "month"], name: "index_user_contributions_on_year_and_month"
  end

  create_table "user_debts", force: :cascade do |t|
    t.integer "user_id"
    t.float "owed"
    t.float "paid"
    t.boolean "paid_off", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_user_debts_on_user_id"
  end

  create_table "user_notifications", force: :cascade do |t|
    t.integer "notification_id"
    t.integer "user_id"
    t.boolean "is_read", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["notification_id", "user_id"], name: "index_user_notifications_on_notification_id_and_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "name", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "role", default: 1, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "phone_number"
    t.integer "address_id"
    t.string "pic_blok"
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.json "tokens"
    t.boolean "kk", default: false
    t.boolean "allow_password_change", default: false, null: false
    t.string "device_type"
    t.string "device_token"
    t.index ["address_id"], name: "index_users_on_address_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
