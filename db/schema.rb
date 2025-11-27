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

ActiveRecord::Schema[8.1].define(version: 2025_11_27_112804) do
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
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_activity_logs_on_action"
    t.index ["admin_id"], name: "index_activity_logs_on_admin_id"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["target_type", "target_id"], name: "index_activity_logs_on_target_type_and_target_id"
  end

  create_table "admins", force: :cascade do |t|
    t.string "clerk_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "role"
    t.datetime "updated_at", null: false
  end

  create_table "golfers", force: :cascade do |t|
    t.string "address"
    t.datetime "checked_in_at"
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "group_id"
    t.integer "hole_number"
    t.string "mobile"
    t.string "name"
    t.text "notes"
    t.string "payment_method"
    t.text "payment_notes"
    t.string "payment_status"
    t.string "payment_type"
    t.string "phone"
    t.integer "position"
    t.string "receipt_number"
    t.string "registration_status"
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.datetime "updated_at", null: false
    t.datetime "waiver_accepted_at"
    t.index ["group_id"], name: "index_golfers_on_group_id"
    t.index ["stripe_checkout_session_id"], name: "index_golfers_on_stripe_checkout_session_id", unique: true, where: "(stripe_checkout_session_id IS NOT NULL)"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_number"
    t.integer "hole_number"
    t.datetime "updated_at", null: false
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

  add_foreign_key "activity_logs", "admins"
  add_foreign_key "golfers", "groups"
end
