class AllowNullFieldsForPendingOrders < ActiveRecord::Migration[8.0]
  def change
    # Allow NULL for fields that are not required when order status is pending
    change_column_null :orders, :total_price_cents, true
    change_column_null :orders, :email, true
    change_column_null :orders, :address_id, true
    change_column_null :orders, :credit_card_id, true

    # Update check constraint to allow NULL for total_price_cents
    # Remove the old constraint
    remove_check_constraint :orders, name: "chk_orders_total_price_cents_non_negative"
    # Add new constraint that allows NULL or non-negative values (without validation for safety)
    add_check_constraint :orders, "total_price_cents IS NULL OR total_price_cents >= 0",
                         name: "chk_orders_total_price_cents_non_negative", validate: false
  end
end
