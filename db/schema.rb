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

ActiveRecord::Schema[8.1].define(version: 2026_11_02_110149) do
  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.string "meta_title"
    t.text "meta_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "post_tags", force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "post_type"
    t.string "youtube_video_id"
    t.datetime "published_at"
    t.string "meta_title"
    t.text "meta_description"
    t.integer "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.integer "category_id", null: false
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
  add_foreign_key "posts", "categories"
end
