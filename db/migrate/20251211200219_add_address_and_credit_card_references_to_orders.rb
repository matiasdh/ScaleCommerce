class AddAddressAndCreditCardReferencesToOrders < ActiveRecord::Migration[8.0]
  def change
    safety_assured do # Orders are created along this transaction
      add_reference :orders, :address, null: false, foreign_key: true
      add_reference :orders, :credit_card, null: false, foreign_key: true
    end
  end
end
