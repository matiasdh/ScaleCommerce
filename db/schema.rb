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

ActiveRecord::Schema[8.0].define(version: 2026_02_08_034725) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "order_status", ["pending", "authorized", "insufficient_funds", "captured", "partially_fulfilled", "fulfilled", "completed", "failed"]

  create_table "addresses", force: :cascade do |t|
    t.string "line_1", null: false
    t.string "line_2"
    t.string "city", null: false
    t.string "state", null: false
    t.string "zip", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credit_cards", force: :cascade do |t|
    t.string "last4", null: false
    t.string "brand", null: false
    t.integer "exp_month", null: false
    t.integer "exp_year", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_products", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.integer "unit_price_cents", null: false
    t.string "unit_price_currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_products_on_order_id_and_product_id", unique: true
    t.index ["order_id"], name: "index_order_products_on_order_id"
    t.index ["product_id"], name: "index_order_products_on_product_id"
    t.check_constraint "quantity > 0", name: "chk_order_products_quantity_positive"
    t.check_constraint "unit_price_cents >= 0", name: "chk_order_products_unit_price_non_negative"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "total_price_cents"
    t.string "email"
    t.string "total_price_currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "address_id"
    t.bigint "credit_card_id"
    t.bigint "shopping_basket_id"
    t.enum "status", default: "pending", null: false, enum_type: "order_status"
    t.index ["address_id"], name: "index_orders_on_address_id"
    t.index ["credit_card_id"], name: "index_orders_on_credit_card_id"
    t.index ["shopping_basket_id"], name: "index_orders_on_shopping_basket_id", unique: true
    t.check_constraint "total_price_cents IS NULL OR total_price_cents >= 0", name: "chk_orders_total_price_cents_non_negative"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stock", default: 0, null: false
    t.integer "price_cents", default: 0, null: false
    t.check_constraint "price_cents > 0", name: "chk_products_price_positive"
    t.check_constraint "stock >= 0", name: "chk_products_stock_non_negative"
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
    t.check_constraint "quantity > 0", name: "chk_shopping_basket_products_quantity_positive"
  end

  create_table "shopping_baskets", force: :cascade do |t|
    t.uuid "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_shopping_baskets_on_uuid", unique: true
  end

  add_foreign_key "order_products", "orders"
  add_foreign_key "order_products", "products"
  add_foreign_key "orders", "addresses"
  add_foreign_key "orders", "credit_cards"
  add_foreign_key "orders", "shopping_baskets", validate: false
  add_foreign_key "shopping_basket_products", "products"
  add_foreign_key "shopping_basket_products", "shopping_baskets"
end
