# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create sample products for testing
products = [
  {
    name: "Premium Wireless Headphones",
    description: "High-quality noise-canceling wireless headphones with 30-hour battery life",
    currency: "usd"
  },
  {
    name: "Smartphone Stand",
    description: "Adjustable aluminum smartphone stand for desk use",
    currency: "usd"
  },
  {
    name: "USB-C Charging Cable (2m)",
    description: "Fast charging USB-C cable with reinforced connectors",
    currency: "usd"
  },
  {
    name: "Portable Power Bank",
    description: "20,000mAh power bank with fast charging support",
    currency: "usd"
  },
  {
    name: "Limited Edition Mechanical Keyboard",
    description: "RGB mechanical keyboard with custom switches - Limited stock!",
    currency: "usd"
  }
]

products.each do |product_attrs|
  product = Product.find_or_create_by!(name: product_attrs[:name]) do |p|
    p.description = product_attrs[:description]
    p.currency = product_attrs[:currency]
  end

  puts "Created/Updated product: #{product.name}"
end

puts "\nSeeding complete! Created #{Product.count} products."
