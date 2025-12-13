FactoryBot.define do
  factory :shopping_basket do
    trait :with_products do
      transient do
        products_count { 3 } # Defaults to 3 products
      end

      after(:create) do |basket, evaluator|
        create_list(:shopping_basket_product, evaluator.products_count, shopping_basket: basket)
      end
    end
  end
end
