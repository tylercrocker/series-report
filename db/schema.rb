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

ActiveRecord::Schema[7.0].define(version: 2023_05_16_004924) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alternate_names", force: :cascade do |t|
    t.string "nameable_type", null: false
    t.bigint "nameable_id", null: false
    t.string "name"
    t.string "language"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nameable_type", "nameable_id", "name", "language"], name: "alternate_names_unique_constraint", unique: true
  end

  create_table "api_fetches", force: :cascade do |t|
    t.string "type", null: false
    t.string "fetchable_type", null: false
    t.bigint "fetchable_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "last_fetched_at"
    t.json "messages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type", "fetchable_type", "fetchable_id"], name: "api_fetches_unique_constraint", unique: true
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

  create_table "identifiers", force: :cascade do |t|
    t.string "identifiable_type", null: false
    t.bigint "identifiable_id", null: false
    t.string "type", null: false
    t.string "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifiable_type", "identifiable_id"], name: "index_identifiers_on_identifiable"
    t.index ["type", "identifier"], name: "edition_identifiers_unique_constraint", unique: true
  end

  create_table "isbn_groups", force: :cascade do |t|
    t.string "type", null: false
    t.string "ean", null: false
    t.string "group", null: false
    t.string "name", null: false
    t.integer "publisher_length", null: false
    t.string "range_start", null: false
    t.string "range_end", null: false
    t.integer "item_length"
    t.string "language_code_type"
    t.string "language_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ean", "group", "publisher_length", "name", "range_start", "range_end"], name: "isbn_groups_unique_constraint", unique: true
  end

  create_table "languages", force: :cascade do |t|
    t.string "iso_639_2", null: false
    t.string "iso_639_2_type"
    t.string "iso_639_1"
    t.string "name_lang", null: false
    t.string "name", null: false
    t.string "name_qualifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["iso_639_1"], name: "index_languages_on_iso_639_1"
    t.index ["iso_639_2", "iso_639_2_type"], name: "languages_iso_lookup"
    t.index ["name"], name: "index_languages_on_name"
    t.index ["name_lang", "name", "iso_639_2", "iso_639_2_type"], name: "languages_unique_constraint", unique: true
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

  create_table "publisher_isbn_registrations", force: :cascade do |t|
    t.bigint "publisher_id", null: false
    t.string "ean", null: false
    t.string "group", null: false
    t.string "number", null: false
    t.integer "open_library_uses", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ean", "group", "number", "publisher_id"], name: "publisher_isbn_registrations_unique_constraint", unique: true
  end

  create_table "publishers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "publishers_unique_constraint", unique: true
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
  add_foreign_key "editions", "works", on_delete: :restrict
  add_foreign_key "publisher_isbn_registrations", "publishers", on_delete: :restrict
  add_foreign_key "taggings", "tags"
end
