require "rails_helper"

RSpec.describe ShoppingBasketBlueprint do
  describe ".render_as_hash" do
    subject { described_class.render_as_hash(shopping_basket) }
    let(:shopping_basket) { create(:shopping_basket) }

    context "when the basket is empty" do
      it "returns an empty products list and zero total price" do
        expect(subject[:products]).to eq([])
        expect(subject[:total_price]).to include(cents: 0, currency: "USD")
      end
    end

    context "when the basket has products" do
      let(:product) { create(:product, price_cents: 10_00) }

      before do
        create(:shopping_basket_product, shopping_basket: shopping_basket, product: product, quantity: 2)
      end

      it "returns the products and the calculated total" do
        expect(subject[:products].size).to eq(1)

        item = subject[:products].first
        expect(item[:id]).to eq(product.id)
        expect(item[:quantity]).to eq(2)

        expect(subject[:total_price]).to include(cents: 2000) # 10_00 * 2 = 2000
      end
    end
  end
end
