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

ActiveRecord::Schema[8.1].define(version: 2026_09_28_184120) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

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

  create_table "knowledge_chunks", force: :cascade do |t|
    t.text "content", null: false
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.vector "embedding", limit: 1024, null: false
    t.string "source_ref", null: false
    t.string "source_type", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["content_hash"], name: "index_knowledge_chunks_on_content_hash", unique: true
    t.index ["embedding"], name: "index_knowledge_chunks_on_embedding", opclass: :vector_cosine_ops, using: :hnsw
  end
end
