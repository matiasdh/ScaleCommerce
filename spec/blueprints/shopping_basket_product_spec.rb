require 'rails_helper'

RSpec.describe ShoppingBasketProductBlueprint do
  describe '.render' do
    let(:product) { create(:product, price_cents: 100_00, stock: 10) }
    let(:shopping_basket_product) { create(:shopping_basket_product, product: product, quantity: 2) }

    subject { described_class.render_as_hash(shopping_basket_product) }

    it "serializes the basic fields" do
      expect(subject).to include(
        id: shopping_basket_product.product.id,
        name: shopping_basket_product.name,
        description: shopping_basket_product.description,
        stock_status: shopping_basket_product.stock_status
      )
    end
  end
end
