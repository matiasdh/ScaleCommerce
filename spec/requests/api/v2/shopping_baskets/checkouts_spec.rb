require 'rails_helper'

RSpec.describe "Api::V2::ShoppingBaskets::Checkouts", type: :request do
  let(:endpoint) { "/api/v2/shopping_basket/checkout" }
  let(:headers) { { "Authorization" => "Bearer #{basket.uuid}" } }

  let(:basket) { create(:shopping_basket) }
  let(:product) { create(:product, stock: 10, price_cents: 10_00) }

  let(:payment_token) { "tok_success" }

  before do
    create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 2)
  end

  let(:valid_params) do
    {
      payment_token: payment_token,
      email: "test@example.com",
      address: {
        line_1: "123 Calle Falsa",
        line_2: "Apt 4",
        city: "Montevideo",
        state: "Montevideo",
        zip: "11300",
        country: "UY"
      }
    }
  end

  describe "POST /api/v2/checkout" do
    context "with valid params and shopping basket" do
      it "returns 202 Accepted" do
        allow(CheckoutOrderJob).to receive(:perform_later)
        post endpoint, params: valid_params, headers: headers
        expect(response).to have_http_status :accepted
      end

      it "creates an order with pending status" do
        allow(CheckoutOrderJob).to receive(:perform_later)

        expect {
          post endpoint, params: valid_params, headers: headers
        }.to change(Order, :count).by(1)

        order = basket.reload.order
        expect(order).to be_present
        expect(order.status).to eq("pending")
      end

      it "creates an order without total_price_cents, email, address, or credit_card" do
        allow(CheckoutOrderJob).to receive(:perform_later)

        post endpoint, params: valid_params, headers: headers

        order = basket.reload.order
        expect(order.total_price_cents).to be_nil
        expect(order.email).to be_nil
        expect(order.address_id).to be_nil
        expect(order.credit_card_id).to be_nil
      end

      it "enqueues CheckoutOrderJob with correct parameters" do
        expect(CheckoutOrderJob).to receive(:perform_later).with(
          shopping_basket_id: basket.id,
          email: "test@example.com",
          payment_token: "tok_success",
          address_params: hash_including(
            "line_1" => "123 Calle Falsa",
            "city" => "Montevideo"
          )
        )

        post endpoint, params: valid_params, headers: headers
      end

      it "returns a message indicating checkout processing started" do
        allow(CheckoutOrderJob).to receive(:perform_later)
        post endpoint, params: valid_params, headers: headers

        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Checkout processing started")
      end
    end

    context "Error Handling" do
      it "returns 400 Bad Request if params are missing" do
        invalid_params = { payment_token: payment_token }

        post endpoint, params: invalid_params, headers: headers

        expect(response).to have_http_status(:bad_request)
      end

      context "when checkout is already being processed" do
        before do
          # Create an order for the shopping basket first
          create(:order, :pending, shopping_basket: basket)
        end

        it "returns 409 Conflict with appropriate message" do
          allow(CheckoutOrderJob).to receive(:perform_later)

          post endpoint, params: valid_params, headers: headers

          expect(response).to have_http_status(:conflict)

          json = JSON.parse(response.body)
          expect(json["error"]["code"]).to eq(409)
          expect(json["error"]["messages"]).to include("Checkout is already being processed")
        end

        it "does not enqueue CheckoutOrderJob again" do
          expect(CheckoutOrderJob).not_to receive(:perform_later)

          post endpoint, params: valid_params, headers: headers
        end

        it "does not create a duplicate order" do
          expect {
            post endpoint, params: valid_params, headers: headers
          }.not_to change(Order, :count)
        end
      end
    end
  end
end
