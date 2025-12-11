FactoryBot.define do
  factory :order_product do
    association :order
    association :product

    quantity { Faker::Number.between(from: 1, to: 10) }

    unit_price_cents { Faker::Number.between(from: 5_00, to: 100_00) }
    unit_price_currency { "USD" }
  end
end
