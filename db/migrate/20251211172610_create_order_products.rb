class CreateOrderProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :order_products do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.integer :unit_price_cents
      t.string :unit_price_currency

      t.timestamps
    end

    add_index :order_products, [ :order_id, :product_id ], unique: true
  end
end
