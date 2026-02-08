class AddShoppingBasketsToOrders < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :orders, :shopping_basket, index: false, foreign_key: false
  end
end
