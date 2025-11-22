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

ActiveRecord::Schema[8.0].define(version: 2025_11_19_031435) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "address_contributions", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "effective_from", null: false
    t.date "effective_until"
    t.text "reason"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_address_contributions_on_active"
    t.index ["address_id", "effective_from", "effective_until"], name: "index_address_contributions_on_period", unique: true
    t.index ["address_id", "effective_from"], name: "index_address_contributions_on_address_id_and_effective_from"
    t.index ["address_id"], name: "index_address_contributions_on_address_id"
    t.index ["effective_from"], name: "index_address_contributions_on_effective_from"
  end

  create_table "addresses", force: :cascade do |t|
    t.string "block_address"
    t.string "block_number"
    t.string "block"
    t.integer "arrears", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "empty", default: false
    t.boolean "free", default: false
  end

  create_table "app_settings", force: :cascade do |t|
    t.text "home_page_text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "starting_balance", precision: 15, scale: 2, default: "0.0"
    t.integer "starting_year", default: 2025
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

  create_table "contributions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "effective_from", null: false
    t.string "block", limit: 1
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_contributions_on_active"
    t.index ["block"], name: "index_contributions_on_block"
    t.index ["effective_from", "block"], name: "index_contributions_on_effective_from_and_block"
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

  create_table "otps", force: :cascade do |t|
    t.string "phone_number"
    t.string "code"
    t.datetime "expires_at"
    t.datetime "verified_at"
    t.integer "attempts"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.string "reference", null: false
    t.bigint "user_id", null: false
    t.bigint "address_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.string "status", default: "UNPAID", null: false
    t.string "payment_method", null: false
    t.string "payment_channel"
    t.text "checkout_url"
    t.text "qr_url"
    t.datetime "expired_at"
    t.datetime "paid_at"
    t.jsonb "tripay_response", default: {}
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_payments_on_address_id"
    t.index ["reference"], name: "index_payments_on_reference", unique: true
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.string "value"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "template_transactions", force: :cascade do |t|
    t.text "description"
    t.integer "transaction_type"
    t.integer "transaction_group"
    t.float "amount"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "user_addresses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "address_id", null: false
    t.boolean "primary", default: false
    t.boolean "kk", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id", "kk"], name: "index_user_addresses_on_address_id_and_kk"
    t.index ["address_id"], name: "index_user_addresses_on_address_id"
    t.index ["user_id", "address_id"], name: "index_user_addresses_on_user_id_and_address_id", unique: true
    t.index ["user_id", "primary"], name: "index_user_addresses_on_user_id_and_primary"
    t.index ["user_id"], name: "index_user_addresses_on_user_id"
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
    t.decimal "expected_contribution", precision: 10, scale: 2
    t.index ["address_id"], name: "index_user_contributions_on_address_id"
    t.index ["expected_contribution"], name: "index_user_contributions_on_expected_contribution"
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
    t.string "pic_blok"
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.json "tokens"
    t.boolean "allow_password_change", default: false, null: false
    t.string "device_type"
    t.string "device_token"
    t.string "login_code"
    t.datetime "login_code_expires_at"
    t.boolean "allow_manage_transfer", default: true
    t.boolean "allow_manage_expense", default: true
    t.string "expo_push_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "address_contributions", "addresses"
  add_foreign_key "payments", "addresses"
  add_foreign_key "payments", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "user_addresses", "addresses"
  add_foreign_key "user_addresses", "users"
end
