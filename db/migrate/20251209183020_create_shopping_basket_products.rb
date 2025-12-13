class CreateShoppingBasketProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_basket_products do |t|
      t.references :shopping_basket, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, default: 1, null: false

      t.timestamps
    end

    add_index :shopping_basket_products, [ :shopping_basket_id, :product_id ], unique: true
  end
end
