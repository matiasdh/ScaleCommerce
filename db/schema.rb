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

ActiveRecord::Schema[8.0].define(version: 2025_12_09_183020) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stock", default: 0, null: false
    t.integer "price_cents", default: 0, null: false
  end

  create_table "shopping_basket_products", force: :cascade do |t|
    t.bigint "shopping_basket_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_shopping_basket_products_on_product_id"
    t.index ["shopping_basket_id", "product_id"], name: "idx_on_shopping_basket_id_product_id_821e8a2fb7", unique: true
    t.index ["shopping_basket_id"], name: "index_shopping_basket_products_on_shopping_basket_id"
  end

  create_table "shopping_baskets", force: :cascade do |t|
    t.uuid "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_shopping_baskets_on_uuid", unique: true
  end

  add_foreign_key "shopping_basket_products", "products"
  add_foreign_key "shopping_basket_products", "shopping_baskets"
end
