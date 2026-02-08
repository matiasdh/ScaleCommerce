class AddShoppingBasketsToOrdersIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :orders, :shopping_basket_id, unique: true, algorithm: :concurrently
    add_foreign_key :orders, :shopping_baskets, column: :shopping_basket_id, validate: false
  end
end
