class CreateCreditCards < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_cards do |t|
      t.string :last4
      t.string :brand
      t.integer :exp_month
      t.integer :exp_year
      t.string :token

      t.timestamps
    end
  end
end
