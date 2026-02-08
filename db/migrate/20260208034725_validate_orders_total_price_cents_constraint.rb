class ValidateOrdersTotalPriceCentsConstraint < ActiveRecord::Migration[8.0]
  def change
    validate_check_constraint :orders, name: "chk_orders_total_price_cents_non_negative"
  end
end
