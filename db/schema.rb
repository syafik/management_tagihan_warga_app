# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_07_051852) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "block_address"
    t.string "block_number"
    t.string "block"
    t.decimal "contribution", precision: 13, scale: 2
    t.integer "arrears", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "empty", default: false
  end

  create_table "cash_flows", force: :cascade do |t|
    t.float "cash_in"
    t.float "cash_out"
    t.float "total"
    t.integer "month"
    t.integer "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["month", "year"], name: "index_cash_flows_on_month_and_year"
  end

  create_table "cash_transactions", force: :cascade do |t|
    t.date "transaction_date"
    t.integer "transaction_type"
    t.float "total"
    t.integer "month"
    t.integer "year"
    t.integer "transaction_group"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "pic_id"
    t.index ["month", "year"], name: "index_cash_transactions_on_month_and_year"
    t.index ["pic_id"], name: "index_cash_transactions_on_pic_id"
  end

  create_table "debts", force: :cascade do |t|
    t.integer "user_id"
    t.float "value"
    t.text "description"
    t.date "debt_date"
    t.integer "debt_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "installments", force: :cascade do |t|
    t.text "description"
    t.float "value"
    t.integer "transaction_type"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "paid_off", default: false
    t.index ["parent_id"], name: "index_installments_on_parent_id"
  end

  create_table "total_contributions", force: :cascade do |t|
    t.integer "year"
    t.integer "month"
    t.string "blok"
    t.float "total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "address_id"
    t.string "blok"
    t.index ["address_id"], name: "index_user_contributions_on_address_id"
    t.index ["year", "month"], name: "index_user_contributions_on_year_and_month"
  end

  create_table "user_debts", force: :cascade do |t|
    t.integer "user_id"
    t.float "owed"
    t.float "paid"
    t.boolean "paid_off", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_debts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "name", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "role", default: 1, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone_number"
    t.integer "address_id"
    t.string "pic_blok"
    t.index ["address_id"], name: "index_users_on_address_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
