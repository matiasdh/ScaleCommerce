class OrderBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :created_at

  association :total_price, blueprint: MoneyBlueprint
  association :order_products, blueprint: OrderProductBlueprint
end
