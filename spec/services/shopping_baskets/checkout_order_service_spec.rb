require "rails_helper"

RSpec.describe ShoppingBaskets::CheckoutOrderService do
  # Setup data
  let(:email)          { "test@example.com" }
  let(:address_params) { attributes_for(:address) }
  # Default to a successful token for happy paths
  let(:card_token)     { "tok_success" }
  let(:basket)         { create(:shopping_basket) }

  # Integration Strategy:
  # We use the REAL PaymentGateway class with 0 latency.
  # This ensures we test the actual integration logic between Service and Gateway,
  # rather than just testing a mock that might drift from reality.
  let(:payment_gateway) { PaymentGateway.new(latency: 0) }

  subject(:service) do
    described_class.new(
      shopping_basket: basket,
      email: email,
      payment_token: card_token,
      address_params: address_params,
      payment_gateway: payment_gateway
    )
  end

  describe "#call" do
    context "when all items are in stock (Happy Path)" do
      let(:product) { create(:product, stock: 10, price_cents: 10_00) }

      before do
        create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 2)
        allow(payment_gateway).to receive(:authorize).and_call_original
        allow(payment_gateway).to receive(:capture).and_call_original
      end

      it "creates an order, snapshots items, and destroys the empty basket" do
        expect {
          service.call
        }.to change(Order, :count).by(1)
         .and change(OrderProduct, :count).by(1)
         .and change(ShoppingBasket, :count).by(-1)

        order = Order.last
        expect(order.total_price_cents).to eq(2000) # 2 * $10.00
        expect(order.email).to eq(email)
      end

      it "creates a CreditCard and Address from the token and params" do
        expect {
          service.call
        }.to change(CreditCard, :count).by(1)
         .and change(Address, :count).by(1)

        credit_card = CreditCard.last
        expect(credit_card.last4).to eq("4242")
        expect(credit_card.token).to eq("tok_success")
      end

      it "decrements product stock accordingly" do
        service.call
        expect(product.reload.stock).to eq(8)
      end

      it "authorizes and captures the payment using the real gateway logic" do
        # Authorize is called with the basket total (before stock filtering)
        expect(payment_gateway).to receive(:authorize).with(
          token: "tok_success",
          amount_cents: 20_00,
          currency: "USD"
        ).and_call_original

        # Capture is called with the order total (after stock filtering)
        expect(payment_gateway).to receive(:capture).with(
          hash_including(
            authorization_id: be_present,
            amount_cents: 20_00,
            currency: "USD"
          )
        ).and_call_original

        service.call
      end
    end

    context "when some items are out of stock (Partial Fulfillment)" do
      let(:in_stock_product)     { create(:product, stock: 5, price_cents: 1000) }
      let(:out_of_stock_product) { create(:product, stock: 0, price_cents: 5000) }

      before do
        create(:shopping_basket_product, shopping_basket: basket, product: in_stock_product,     quantity: 1)
        create(:shopping_basket_product, shopping_basket: basket, product: out_of_stock_product, quantity: 1)
        allow(payment_gateway).to receive(:authorize).and_call_original
        allow(payment_gateway).to receive(:capture).and_call_original
      end

      it "creates the order only for available items and keeps the basket alive" do
        # Authorize is called with the BASKET total ($10 + $50 = $60)
        expect(payment_gateway).to receive(:authorize).with(
          hash_including(amount_cents: 60_00)
        ).and_call_original

        # Capture is called with the ORDER total ($10 only)
        expect(payment_gateway).to receive(:capture).with(
          hash_including(amount_cents: 10_00)
        ).and_call_original

        # Smart Cleanup: Order is created, but Basket is NOT destroyed
        # because it still contains the out-of-stock item.
        expect {
          service.call
        }.to change(Order, :count).by(1)
         .and change(ShoppingBasket, :count).by(0)

        basket.reload
        # Verify only the out-of-stock item remains
        expect(basket.shopping_basket_products.count).to eq(1)
        expect(basket.shopping_basket_products.first.product).to eq(out_of_stock_product)
      end
    end

    context "when all items are unavailable (No purchasable stock)" do
      let(:product) { create(:product, stock: 0, price_cents: 10_00) }

      before do
        create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 1)
        allow(payment_gateway).to receive(:authorize).and_call_original
      end

      it "raises EmptyBasketError after authorizing but before capturing" do
        # Authorize IS called (it happens before the guard clause inside the transaction)
        expect(payment_gateway).to receive(:authorize).and_call_original
        # Capture is NOT called (error raised before we reach it)
        expect(payment_gateway).not_to receive(:capture)

        expect {
          service.call
        }.to raise_error(ShoppingBaskets::CheckoutOrderService::EmptyBasketError)
         .and change(Order, :count).by(0)
      end

      it "rolls back CreditCard and Address creation" do
        expect {
          begin
            service.call
          rescue ShoppingBaskets::CheckoutOrderService::EmptyBasketError
          end
        }.to change(CreditCard, :count).by(0)
         .and change(Address, :count).by(0)
      end
    end

    context "when payment authorization fails" do
      let(:product) { create(:product, stock: 10, price_cents: 10_00) }
      let(:card_token) { "tok_fail" }

      before do
        create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 1)
      end

      it "performs a transaction rollback (no stock, order, credit card, or address changes)" do
        expect {
          begin
            service.call
          rescue ShoppingBaskets::CheckoutOrderService::PaymentError
          end
        }.to change(Order, :count).by(0)
         .and change { product.reload.stock }.by(0)
         .and change(CreditCard, :count).by(0)
         .and change(Address, :count).by(0)
         .and change(ShoppingBasket, :count).by(0)
      end

      it "raises PaymentError with the message from the real gateway" do
        expect {
          service.call
        }.to raise_error(ShoppingBaskets::CheckoutOrderService::PaymentError, "Insufficient funds")
      end
    end

    context "locking behavior" do
      let(:product) { create(:product, stock: 10, price_cents: 10_00) }

      before do
        create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 1)
        allow(payment_gateway).to receive(:authorize).and_call_original
        allow(payment_gateway).to receive(:capture).and_call_original
      end

      it "locks the basket and the associated products using FOR UPDATE" do
        expect(basket).to receive(:lock!).and_call_original

        # Verify Product Chain Lock
        # We mock the exact ActiveRecord chain to ensure the query is built correctly
        # Product.where(...) -> .order(:id) -> .lock -> .index_by
        relation_spy = instance_double(ActiveRecord::Relation)

        allow(Product).to receive(:where).and_return(relation_spy)
        allow(relation_spy).to receive(:order).with(:id).and_return(relation_spy)
        expect(relation_spy).to receive(:lock).and_return(relation_spy)
        allow(relation_spy).to receive(:index_by).and_return({ product.id => product })

        service.call
      end
    end
  end
end
