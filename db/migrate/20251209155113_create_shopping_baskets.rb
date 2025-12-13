class CreateShoppingBaskets < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_baskets do |t|
      t.uuid :uuid, null: false

      t.timestamps
    end
    add_index :shopping_baskets, :uuid, unique: true
  end
end
