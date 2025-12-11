require 'rails_helper'

RSpec.describe OrderProductBlueprint do
  let(:product) { create(:product) }
  let(:order) { create(:order) }
  let(:order_product) do
    create(:order_product,
      order: order,
      product: product,
      quantity: 3,
      unit_price_cents: product.price_cents,
      unit_price_currency: "USD"
    )
  end

  subject { described_class.render_as_hash(order_product) }

  it "serializes the item attributes correctly" do
    expect(subject[:quantity]).to eq 3
    expect(subject[:name]).to eq product.name
  end

  it "serializes the unit price (frozen price) as a Money object structure" do
    expect(subject[:unit_price]).to eq({
      cents: product.price.cents,
      currency: "USD"
    })
  end

  it "serializes the total price for the line item as a Money object structure" do
    expect(subject[:total_price]).to eq({
      cents: product.price.cents * order_product.quantity,
      currency: "USD"
    })
  end
end
