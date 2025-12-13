FactoryBot.define do
  factory :shopping_basket_product do
    association :shopping_basket
    association :product
    quantity { 1 }
  end
end
