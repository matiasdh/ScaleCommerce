class ProductBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :stock_status
  association :price, blueprint: MoneyBlueprint
end
