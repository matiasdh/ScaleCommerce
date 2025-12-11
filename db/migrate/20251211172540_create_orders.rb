class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.integer :total_price_cents
      t.string :email
      t.string :total_price_currency

      t.timestamps
    end
  end
end
