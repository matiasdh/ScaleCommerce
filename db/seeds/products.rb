require "faker"
Faker::Config.random = Random.new(12) # Ensures consistent values on every run (idempotency)

total_products = 150
puts "🌱 Seeding #{total_products} products..."

total_products.times do |i|
  name = Faker::Commerce.product_name
  description = Faker::Lorem.paragraph(sentence_count: 3)
  price_cents = Faker::Number.between(from: 10, to: 500) * 100
  stock = Faker::Number.between(from: 0, to: 1500)

  product = Product.find_or_initialize_by(name: "#{name} #{i}")
  product.description = description
  product.price_cents = price_cents
  product.currency = "usd"
  product.stock = stock

  product.save!
end

puts "✅ Products seeding completed. Total: #{Product.count}"
