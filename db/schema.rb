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

ActiveRecord::Schema[7.2].define(version: 2025_04_04_074722) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "activities", force: :cascade do |t|
    t.string "trackable_type"
    t.bigint "trackable_id"
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "key"
    t.text "parameters"
    t.string "recipient_type"
    t.bigint "recipient_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["owner_type", "owner_id"], name: "index_activities_on_owner"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["recipient_type", "recipient_id"], name: "index_activities_on_recipient"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "access_level", default: 3, null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "lease_agreement_units", force: :cascade do |t|
    t.bigint "lease_agreement_id", null: false
    t.bigint "unit_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lease_agreement_id"], name: "index_lease_agreement_units_on_lease_agreement_id"
    t.index ["unit_id"], name: "index_lease_agreement_units_on_unit_id"
  end

  create_table "lease_agreements", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.decimal "rent_amount"
    t.decimal "security_deposit"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "annual_increment"
    t.string "increment_frequency"
    t.string "increment_type"
    t.bigint "property_id"
    t.integer "pending_rent", default: 0, null: false
    t.index ["property_id"], name: "index_lease_agreements_on_property_id"
    t.index ["tenant_id"], name: "index_lease_agreements_on_tenant_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "zip_code"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "units_count"
    t.integer "property_type"
  end

  create_table "rents", force: :cascade do |t|
    t.decimal "amount"
    t.date "payment_date"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_advance"
    t.date "due_date"
    t.bigint "lease_agreement_id", null: false
    t.string "payment_method"
    t.integer "amount_paid"
    t.index ["lease_agreement_id"], name: "index_rents_on_lease_agreement_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "balance", default: "0.0"
    t.decimal "advance_credit", precision: 10, scale: 2, default: "0.0", null: false
    t.string "cnic"
    t.string "receipt_image", default: [], array: true
  end

  create_table "units", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "unit_number"
    t.string "floor"
    t.integer "square_footage"
    t.decimal "rental_rate"
    t.decimal "selling_rate"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_units_on_property_id"
  end

  create_table "user_lease_agreements", force: :cascade do |t|
    t.bigint "user_property_id", null: false
    t.bigint "lease_agreement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lease_agreement_id"], name: "index_user_lease_agreements_on_lease_agreement_id"
    t.index ["user_property_id"], name: "index_user_lease_agreements_on_user_property_id"
  end

  create_table "user_properties", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_user_properties_on_property_id"
    t.index ["user_id", "property_id"], name: "index_user_properties_on_user_id_and_property_id", unique: true
    t.index ["user_id"], name: "index_user_properties_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.string "phone_number", default: "", null: false
    t.boolean "profile_completed", default: false, null: false
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
  end

  add_foreign_key "lease_agreement_units", "lease_agreements"
  add_foreign_key "lease_agreement_units", "units"
  add_foreign_key "lease_agreements", "properties"
  add_foreign_key "lease_agreements", "tenants"
  add_foreign_key "rents", "lease_agreements"
  add_foreign_key "units", "properties"
  add_foreign_key "user_lease_agreements", "lease_agreements"
  add_foreign_key "user_lease_agreements", "user_properties"
  add_foreign_key "user_properties", "properties"
  add_foreign_key "user_properties", "users"
end
