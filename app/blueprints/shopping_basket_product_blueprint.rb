class ShoppingBasketProductBlueprint < Blueprinter::Base
  identifier :product_id, name: :id

  field :quantity
  field :name
  field :description
  field :stock_status

  association :total_price, blueprint: MoneyBlueprint
end
