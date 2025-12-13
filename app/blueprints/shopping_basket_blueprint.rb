class ShoppingBasketBlueprint < Blueprinter::Base
  association :shopping_basket_products, blueprint: ShoppingBasketProductBlueprint, name: :products
  association :total_price, blueprint: MoneyBlueprint
end
