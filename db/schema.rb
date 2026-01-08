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

ActiveRecord::Schema[8.1].define(version: 2026_01_08_080919) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.text "details"
    t.jsonb "metadata", default: {}
    t.integer "target_id"
    t.string "target_name"
    t.string "target_type"
    t.bigint "tournament_id"
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_activity_logs_on_action"
    t.index ["admin_id"], name: "index_activity_logs_on_admin_id"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["target_type", "target_id"], name: "index_activity_logs_on_target_type_and_target_id"
    t.index ["tournament_id"], name: "index_activity_logs_on_tournament_id"
  end

  create_table "admins", force: :cascade do |t|
    t.string "clerk_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "role"
    t.datetime "updated_at", null: false
  end

  create_table "employee_numbers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "employee_name"
    t.string "employee_number", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "used", default: false, null: false
    t.bigint "used_by_golfer_id"
    t.index ["tournament_id", "employee_number"], name: "index_employee_numbers_on_tournament_id_and_employee_number", unique: true
    t.index ["tournament_id"], name: "index_employee_numbers_on_tournament_id"
    t.index ["used_by_golfer_id"], name: "index_employee_numbers_on_used_by_golfer_id"
  end

  create_table "golfers", force: :cascade do |t|
    t.string "address"
    t.datetime "checked_in_at"
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "employee_number"
    t.bigint "employee_number_record_id"
    t.bigint "group_id"
    t.integer "hole_number"
    t.boolean "is_employee", default: false, null: false
    t.string "mobile"
    t.string "name"
    t.text "notes"
    t.datetime "paid_at"
    t.integer "payment_amount_cents"
    t.string "payment_method"
    t.text "payment_notes"
    t.string "payment_status"
    t.string "payment_token"
    t.string "payment_type"
    t.string "phone"
    t.integer "position"
    t.string "receipt_number"
    t.integer "refund_amount_cents"
    t.text "refund_reason"
    t.datetime "refunded_at"
    t.integer "refunded_by_id"
    t.string "registration_status"
    t.string "stripe_card_brand"
    t.string "stripe_card_last4"
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.string "stripe_refund_id"
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "waiver_accepted_at"
    t.index ["employee_number_record_id"], name: "index_golfers_on_employee_number_record_id"
    t.index ["group_id"], name: "index_golfers_on_group_id"
    t.index ["paid_at"], name: "index_golfers_on_paid_at"
    t.index ["payment_token"], name: "index_golfers_on_payment_token", unique: true
    t.index ["stripe_checkout_session_id"], name: "index_golfers_on_stripe_checkout_session_id", unique: true, where: "(stripe_checkout_session_id IS NOT NULL)"
    t.index ["stripe_refund_id"], name: "index_golfers_on_stripe_refund_id", unique: true, where: "(stripe_refund_id IS NOT NULL)"
    t.index ["tournament_id", "email"], name: "index_golfers_on_tournament_id_and_email", unique: true
    t.index ["tournament_id"], name: "index_golfers_on_tournament_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_number"
    t.integer "hole_number"
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_groups_on_tournament_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "admin_email"
    t.string "checks_payable_to", default: "GIAAEO"
    t.string "contact_name", default: "Peter Torres"
    t.string "contact_phone", default: "671.689.8677"
    t.datetime "created_at", null: false
    t.string "event_date", default: "January 9, 2026"
    t.string "fee_includes", default: "Green Fee, Ditty Bag, Drinks & Food"
    t.string "format_name", default: "Individual Callaway"
    t.string "location_address", default: "Windward Hills, Guam"
    t.string "location_name", default: "Country Club of the Pacific"
    t.integer "max_capacity"
    t.string "payment_mode", default: "test"
    t.boolean "registration_open", default: true, null: false
    t.string "registration_time", default: "11:00 am"
    t.string "start_time", default: "12:30 pm"
    t.string "stripe_public_key"
    t.string "stripe_secret_key"
    t.string "stripe_webhook_secret"
    t.string "tournament_edition", default: "5th"
    t.integer "tournament_entry_fee", default: 12500
    t.string "tournament_name", default: "Edward A.P. Muna II Memorial Golf Tournament"
    t.string "tournament_title", default: "AIRPORT WEEK"
    t.string "tournament_year", default: "2026"
    t.datetime "updated_at", null: false
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "checks_payable_to"
    t.string "contact_name"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.string "edition"
    t.integer "employee_entry_fee", default: 5000
    t.integer "entry_fee", default: 12500
    t.string "event_date"
    t.string "fee_includes"
    t.string "format_name"
    t.string "location_address"
    t.string "location_name"
    t.integer "max_capacity", default: 160
    t.string "name", null: false
    t.boolean "registration_open", default: false, null: false
    t.string "registration_time"
    t.integer "reserved_slots", default: 0, null: false
    t.string "start_time"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["status", "year"], name: "index_tournaments_on_status_and_year"
    t.index ["status"], name: "index_tournaments_on_status"
    t.index ["year"], name: "index_tournaments_on_year"
  end

  add_foreign_key "activity_logs", "admins"
  add_foreign_key "activity_logs", "tournaments"
  add_foreign_key "employee_numbers", "golfers", column: "used_by_golfer_id"
  add_foreign_key "employee_numbers", "tournaments"
  add_foreign_key "golfers", "admins", column: "refunded_by_id", on_delete: :nullify
  add_foreign_key "golfers", "employee_numbers", column: "employee_number_record_id"
  add_foreign_key "golfers", "groups"
  add_foreign_key "golfers", "tournaments"
  add_foreign_key "groups", "tournaments"
end
