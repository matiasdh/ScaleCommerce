class OrderProductBlueprint < Blueprinter::Base
  identifier :product_id, name: :id
  fields :quantity, :name, :description

  association :total_price, blueprint: MoneyBlueprint
  association :unit_price, blueprint: MoneyBlueprint
end
