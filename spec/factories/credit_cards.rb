FactoryBot.define do
  factory :credit_card do
    last4 { Faker::Number.number(digits: 4).to_s }
    brand { [ "Visa", "MasterCard", "Amex" ].sample }
    exp_month { Faker::Number.between(from: 1, to: 12) }
    exp_year { Faker::Number.between(from: Date.today.year + 1, to: Date.today.year + 5) }
    token { "tok_success" }
  end
end
