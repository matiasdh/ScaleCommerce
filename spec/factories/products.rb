FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    currency { "USD" }
    stock { Faker::Number.between(from: 1, to: 100) }
    price_cents { Faker::Number.between(from: 500, to: 5000) }

    trait :out_of_stock do
      stock { 0 }
    end
  end
end
