class AddStatusToOrders < ActiveRecord::Migration[8.0]
  create_enum :order_status, [
    "pending",
    "authorized",
    "insufficient_funds",
    "captured",
    "partially_fulfilled",
    "fulfilled",
    "completed",
    "failed"
  ]

  def change
    add_column :orders, :status, :enum, enum_type: :order_status, default: "pending", null: false
  end
end
