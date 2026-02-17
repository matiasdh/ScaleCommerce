require "rails_helper"

RSpec.describe ShoppingBaskets::CheckoutOrderAtomicService do
  let(:basket) { create(:shopping_basket) }
  let(:product) { create(:product, stock: 10, price_cents: 10_00) }
  let(:order) { basket.create_order!(status: :pending) }
  let(:payment_gateway) { PaymentGateway.new(latency: 0) }

  before do
    create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 2)
  end

  subject(:service) do
    described_class.new(
      shopping_basket: basket,
      email: "test@example.com",
      payment_token: "tok_success",
      address_params: attributes_for(:address),
      order: order,
      payment_gateway: payment_gateway
    )
  end

  describe "#call" do
    it "updates the order and completes checkout" do
      basket_reloaded = ShoppingBasket.with_associations.find(basket.id)

      result = described_class.call(
        shopping_basket: basket_reloaded,
        email: "test@example.com",
        payment_token: "tok_success",
        address_params: attributes_for(:address),
        order: order,
        payment_gateway: payment_gateway
      )

      expect(result).to be_completed
      expect(result.total_price_cents).to eq(2000)
    end
  end
end
