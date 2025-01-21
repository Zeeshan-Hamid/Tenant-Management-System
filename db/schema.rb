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

ActiveRecord::Schema[7.2].define(version: 2024_11_03_180126) do
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

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "lease_agreements", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "unit_id", null: false
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
    t.index ["tenant_id"], name: "index_lease_agreements_on_tenant_id"
    t.index ["unit_id"], name: "index_lease_agreements_on_unit_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "property_type"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "zip_code"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "units_count"
  end

  create_table "rents", force: :cascade do |t|
    t.bigint "unit_id", null: false
    t.bigint "tenant_id", null: false
    t.decimal "amount"
    t.date "payment_date"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_advance"
    t.index ["tenant_id"], name: "index_rents_on_tenant_id"
    t.index ["unit_id"], name: "index_rents_on_unit_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.boolean "active"
    t.bigint "unit_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "balance", default: "0.0"
    t.decimal "advance_credit", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["unit_id", "active"], name: "unique_active_tenant_per_unit", unique: true, where: "active"
    t.index ["unit_id"], name: "index_tenants_on_unit_id"
  end

  create_table "units", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "unit_number"
    t.string "floor"
    t.integer "square_footage"
    t.decimal "rental_rate"
    t.decimal "selling_rate"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_units_on_property_id"
  end

  add_foreign_key "lease_agreements", "tenants"
  add_foreign_key "lease_agreements", "units"
  add_foreign_key "rents", "tenants"
  add_foreign_key "rents", "units"
  add_foreign_key "tenants", "units"
  add_foreign_key "units", "properties"
end
