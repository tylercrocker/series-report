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

ActiveRecord::Schema[7.0].define(version: 2023_04_14_210953) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alternate_names", force: :cascade do |t|
    t.string "nameable_type", null: false
    t.bigint "nameable_id", null: false
    t.string "name"
    t.string "language"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "collection_items", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.string "collection_itemable_type", null: false
    t.bigint "collection_itemable_id", null: false
    t.decimal "position", precision: 6, scale: 3
    t.string "position_extra"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "collection_itemable_type", "collection_itemable_id"], name: "collection_items_unique_constraint", unique: true
    t.index ["collection_itemable_type", "collection_itemable_id"], name: "reverse_index"
  end

  create_table "collections", force: :cascade do |t|
    t.string "type", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type", "slug"], name: "collections_unique_constraint", unique: true
  end

  create_table "contributions", force: :cascade do |t|
    t.string "type", null: false
    t.bigint "person_id", null: false
    t.string "contributable_type", null: false
    t.bigint "contributable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contributable_id", "contributable_type", "person_id", "type"], name: "contributions_unique_constraint", unique: true
  end

  create_table "edit_requests", force: :cascade do |t|
    t.string "source", null: false
    t.bigint "created_by_id"
    t.string "type", null: false
    t.string "editable_type", null: false
    t.bigint "editable_id", null: false
    t.integer "status"
    t.json "request"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["editable_type", "editable_id"], name: "index_edit_requests_on_editable"
  end

  create_table "edition_identifiers", force: :cascade do |t|
    t.bigint "edition_id", null: false
    t.string "type", null: false
    t.string "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["edition_id"], name: "index_edition_identifiers_on_edition_id"
    t.index ["identifier", "type"], name: "edition_identifiers_unique_constraint", unique: true
  end

  create_table "editions", force: :cascade do |t|
    t.bigint "work_id", null: false
    t.string "type", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.text "notes"
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_id", "type", "slug"], name: "editions_unique_constraint", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.string "slug"
    t.string "name", null: false
    t.string "name_last_first", null: false
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_people_on_name"
    t.index ["name_last_first"], name: "index_people_on_name_last_first"
    t.index ["slug"], name: "people_unique_constraint", unique: true
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "taggable_type"
    t.bigint "taggable_id"
    t.string "tagger_type"
    t.bigint "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "works", force: :cascade do |t|
    t.string "type", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.integer "year_published"
    t.date "published_on"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type", "slug"], name: "works_unique_constraint", unique: true
  end

  add_foreign_key "collection_items", "collections", on_delete: :restrict
  add_foreign_key "contributions", "people", on_delete: :restrict
  add_foreign_key "edition_identifiers", "editions", on_delete: :cascade
  add_foreign_key "editions", "works", on_delete: :restrict
  add_foreign_key "taggings", "tags"
end
