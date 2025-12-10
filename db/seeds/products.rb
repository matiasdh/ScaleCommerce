require "faker"

Faker::Config.random = Random.new(12) # Ensures consistent values on every run (idempotency)

puts "🌱 Seeding products..."

150.times do
  product_name = Faker::Commerce.product_name

  Product.find_or_create_by!(name: product_name) do |product|
    product.description = Faker::Lorem.paragraph(sentence_count: 3)
    product.price_cents = Faker::Number.between(from: 10, to: 500) * 100
    product.currency = "usd"
    product.stock = Faker::Number.between(from: 0, to: 1500)
  end
end

puts "✅ Products seeding completed. Total: #{Product.count}"
