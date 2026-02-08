FactoryBot.define do
  factory :order do
    credit_card
    address

    email { Faker::Internet.email }

    total_price_cents { Faker::Number.between(from: 10_00, to: 500_00) }
    total_price_currency { "USD" }

    trait :pending do
      status { :pending }
      total_price_cents { nil }
      email { nil }
      address { nil }
      credit_card { nil }
    end

    trait :with_products do
      transient do
        items_count { 3 }
      end

      after(:create) do |order, evaluator|
        create_list(:order_product, evaluator.items_count, order: order)

        order.update(total_price_cents: order.order_products.sum(&:total_price))
      end
    end
  end
end
