class AddStockAndPriceCentsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :stock, :integer, null: false, default: 0
    add_column :products, :price_cents, :integer, null: false, default: 0
  end
end
