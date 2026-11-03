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

ActiveRecord::Schema[8.1].define(version: 2026_11_03_161000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "books", force: :cascade do |t|
    t.string "serial_number", limit: 6, null: false
    t.string "title", null: false
    t.string "author", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["serial_number"], name: "index_books_on_serial_number", unique: true
  end

  create_table "borrowings", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "reader_id", null: false
    t.datetime "borrowed_at", null: false
    t.date "due_on", null: false
    t.datetime "returned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_borrowings_on_book_id"
    t.index ["book_id"], name: "index_borrowings_one_open_loan_per_book", unique: true, where: "(returned_at IS NULL)"
    t.index ["due_on"], name: "index_borrowings_open_due_on", where: "(returned_at IS NULL)"
    t.index ["reader_id"], name: "index_borrowings_on_reader_id"
  end

  create_table "readers", force: :cascade do |t|
    t.string "card_number", limit: 6, null: false
    t.string "full_name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["card_number"], name: "index_readers_on_card_number", unique: true
    t.index ["email"], name: "index_readers_on_email", unique: true
  end

  add_foreign_key "borrowings", "books"
  add_foreign_key "borrowings", "readers"
end
