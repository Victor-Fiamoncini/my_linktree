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

ActiveRecord::Schema[8.1].define(version: 2026_08_31_133749) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "agent_connections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "tool", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_agent_connections_on_created_at"
  end

  create_table "bookings", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "slot_start", null: false
    t.datetime "updated_at", null: false
    t.index ["slot_start"], name: "index_bookings_on_slot_start", unique: true
  end
end
