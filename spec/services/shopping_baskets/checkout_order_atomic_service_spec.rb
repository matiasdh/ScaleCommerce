require "rails_helper"

RSpec.describe ShoppingBaskets::CheckoutOrderAtomicService do
  let(:email) { "test@example.com" }
  let(:address_params) { attributes_for(:address) }
  let(:payment_token) { "tok_success" }
  let(:basket) { create(:shopping_basket) }
  let(:basket_with_associations) { ShoppingBasket.with_associations.find(basket.id) }
  let(:payment_gateway) { PaymentGateway.new(latency: 0) }
  let(:checkout_payment_token) { payment_token }

  let(:service) do
    described_class.new(
      shopping_basket: basket_with_associations,
      email:,
      payment_token: checkout_payment_token,
      address_params:,
      order:,
      payment_gateway:
    )
  end

  let(:checkout_result) { service.call }

  describe "#call" do
    context "when all items are in stock (Happy Path)" do
      let(:product) { create(:product, stock: 10, price_cents: 10_00) }
      let(:order) { basket.create_order!(status: :pending) }
      let!(:basket_item) { create(:shopping_basket_product, shopping_basket: basket, product:, quantity: 2) }

      it "updates the order and completes checkout" do
        expect(checkout_result).to be_completed
        expect(checkout_result.total_price_cents).to eq(2000)
        expect(checkout_result.email).to eq(email)
      end

      it "creates CreditCard and Address, decrements stock, destroys empty basket" do
        expect { checkout_result }.to change(CreditCard, :count).by(1)
         .and change(Address, :count).by(1)
         .and change(ShoppingBasket, :count).by(-1)

        expect(product.reload.stock).to eq(8)
      end

      it "authorizes and captures the payment" do
        expect(payment_gateway).to receive(:authorize).with(
          token: "tok_success",
          amount_cents: 20_00,
          currency: "USD"
        ).and_call_original
        expect(payment_gateway).to receive(:capture).with(
          hash_including(authorization_id: be_present, amount_cents: 20_00, currency: "USD")
        ).and_call_original

        checkout_result
      end
    end

    context "when some items are out of stock (Partial Fulfillment)" do
      let(:in_stock_product) { create(:product, stock: 5, price_cents: 1000) }
      let(:out_of_stock_product) { create(:product, stock: 0, price_cents: 5000) }
      let(:order) { basket.create_order!(status: :pending) }
      let!(:in_stock_item) { create(:shopping_basket_product, shopping_basket: basket, product: in_stock_product, quantity: 1) }
      let!(:out_of_stock_item) { create(:shopping_basket_product, shopping_basket: basket, product: out_of_stock_product, quantity: 1) }

      it "updates order only for available items and keeps basket alive" do
        expect(payment_gateway).to receive(:authorize).with(hash_including(amount_cents: 60_00)).and_call_original
        expect(payment_gateway).to receive(:capture).with(hash_including(amount_cents: 10_00)).and_call_original

        expect(checkout_result).to be_completed
        expect(checkout_result.total_price_cents).to eq(1000)
        expect(ShoppingBasket.exists?(basket.id)).to be true
        expect(basket.reload.shopping_basket_products.count).to eq(1)
        expect(basket.shopping_basket_products.first.product).to eq(out_of_stock_product)
      end
    end

    context "when all items are unavailable" do
      let(:product) { create(:product, stock: 0, price_cents: 10_00) }
      let(:order) { basket.create_order!(status: :pending) }
      let!(:basket_item) { create(:shopping_basket_product, shopping_basket: basket, product:, quantity: 1) }

      it "raises EmptyBasketError after authorizing but before capturing" do
        expect(payment_gateway).to receive(:authorize).and_call_original
        expect(payment_gateway).not_to receive(:capture)

        expect { checkout_result }.to raise_error(described_class::EmptyBasketError, "No items available in stock.")
      end

      it "rolls back CreditCard and Address creation" do
        expect { checkout_result rescue described_class::EmptyBasketError }.to change(CreditCard, :count).by(0).and change(Address, :count).by(0)
      end
    end

    context "when payment authorization fails" do
      let(:product) { create(:product, stock: 10, price_cents: 10_00) }
      let(:order) { basket.create_order!(status: :pending) }
      let(:checkout_payment_token) { "tok_fail" }
      let!(:basket_item) { create(:shopping_basket_product, shopping_basket: basket, product:, quantity: 1) }

      it "does not change stock, order, credit card, or address" do
        expect { checkout_result rescue described_class::PaymentError }.to change { product.reload.stock }.by(0)
         .and change(CreditCard, :count).by(0)
         .and change(Address, :count).by(0)
      end

      it "raises PaymentError with gateway message" do
        expect { checkout_result }.to raise_error(described_class::PaymentError, "Insufficient funds")
      end
    end

    context "when order is not pending or failed" do
      let(:product) { create(:product, stock: 10, price_cents: 10_00) }
      let(:order) { basket.create_order!(status: :pending) }
      let!(:basket_item) { create(:shopping_basket_product, shopping_basket: basket, product:, quantity: 1) }
      let!(:order_authorized) { order.update_columns(status: "authorized", total_price_cents: 1000, email: "x@x.com"); order }

      it "raises PaymentError" do
        expect { checkout_result }.to raise_error(described_class::PaymentError, "Order must be pending or failed to authorize")
      end
    end
  end

  describe "#build_reserve_stock_sql" do
    let(:order) { basket.create_order!(status: :pending) }

    def build_sql(basket_items)
      service.send(:build_reserve_stock_sql, basket_items)
    end

    it "generates exact SQL for single item" do
      item = instance_double(ShoppingBasketProduct, product_id: 1, quantity: 2)

      expect(build_sql([ item ])).to eq(
        'UPDATE "products" p SET stock = p.stock - items.quantity, updated_at = NOW() ' \
        'FROM (VALUES (1, 2)) AS items(product_id, quantity) ' \
        'WHERE p.id = items.product_id AND p.stock >= items.quantity ' \
        'RETURNING p.id AS product_id, items.quantity'
      )
    end

    it "generates exact SQL for multiple items" do
      items = [
        instance_double(ShoppingBasketProduct, product_id: 10, quantity: 1),
        instance_double(ShoppingBasketProduct, product_id: 20, quantity: 5)
      ]

      expect(build_sql(items)).to eq(
        'UPDATE "products" p SET stock = p.stock - items.quantity, updated_at = NOW() ' \
        'FROM (VALUES (10, 1), (20, 5)) AS items(product_id, quantity) ' \
        'WHERE p.id = items.product_id AND p.stock >= items.quantity ' \
        'RETURNING p.id AS product_id, items.quantity'
      )
    end

    it "returns valid SQL that can be executed" do
      product = create(:product, stock: 10)
      item = create(:shopping_basket_product, product:, quantity: 2)
      sql = build_sql([ item ])

      result = Product.connection.exec_query(sql)
      expect(result.rows.size).to eq(1)
      expect(result.first["product_id"]).to eq(product.id)
      expect(result.first["quantity"]).to eq(2)
    end
  end
end
