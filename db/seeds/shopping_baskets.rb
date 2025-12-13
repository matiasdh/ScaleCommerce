Faker::Config.random = Random.new(42) # Ensures consistent values on every run (idempotency)

product_ids = Product.order(:id).pluck(:id)

if product_ids.empty?
  puts "⚠️  No products found! Seed products first."
  return
end

total_baskets = 500
puts "🛒 Seeding #{total_baskets} Shopping Baskets..."

total_baskets.times do |i|
  uuid = Faker::Internet.uuid
  number_of_items = Faker::Number.between(from: 1, to: 5)

  selected_product_ids = product_ids.sample(number_of_items, random: Faker::Config.random)

  basket = ShoppingBasket.find_or_create_by!(uuid: uuid)

  selected_product_ids.each do |product_id|
    qty = Faker::Number.between(from: 1, to: 10)

    item = basket.shopping_basket_products.find_or_initialize_by(product_id: product_id)
    item.quantity = qty
    item.save!(validate: false) if item.changed?
  end
end

puts "✅ Shopping Baskets seeding completed. Total: #{ShoppingBasket.count}"
