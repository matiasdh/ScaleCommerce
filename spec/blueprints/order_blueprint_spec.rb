require "rails_helper"

RSpec.describe OrderBlueprint do
  describe ".render_as_hash" do
    subject { described_class.render_as_hash(order) }
    let(:order) { create(:order, :with_products) }

    it "returns the products and the calculated total" do
      expect(subject[:order_products].size).to eq 3

      order_product = order.order_products.first
      item = subject[:order_products].first
      expect(item[:id]).to eq(order_product.product_id)
      expect(item[:quantity]).to eq order_product.quantity

      expect(subject[:total_price]).to include(cents: order.total_price.cents) # 10_00 * 2 = 2000
    end
  end
end
