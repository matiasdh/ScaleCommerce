require 'rails_helper'

RSpec.describe "Api::V1::ShoppingBaskets::Checkouts", type: :request do
  let(:endpoint) { "/api/v1/shopping_basket/checkout" }
  let(:headers) { { "Authorization" => "Bearer #{basket.uuid}" } }

  let(:basket) { create(:shopping_basket) }

  let(:payment_token) { "tok_success" }

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

  let(:created_order) { create(:order, email: "test@example.com") }

  before do
    allow(ShoppingBaskets::CheckoutOrderService).to receive(:call).and_return(created_order)
  end

  describe "POST /api/v1/checkout" do
    context "with valid params and shopping basket" do
      it "returns 201 Created" do
        post endpoint, params: valid_params, headers: headers
        expect(response).to have_http_status :created
      end

      it "calls the CheckoutOrderService with the raw params" do
        expect(ShoppingBaskets::CheckoutOrderService).to receive(:call).with(
          shopping_basket: basket,
          email: "test@example.com",
          payment_token: "tok_success",
          address_params: hash_including(
            "line_1" => "123 Calle Falsa",
            "city" => "Montevideo"
          )
        ).and_return(created_order)

        post endpoint, params: valid_params, headers: headers
      end

      it "returns the serialized order using OrderBlueprint" do
        post endpoint, params: valid_params, headers: headers

        json = JSON.parse(response.body)
        expect(json["id"]).to eq(created_order.id)
      end
    end

    context "when the checkout fails" do
      before do
        allow(ShoppingBaskets::CheckoutOrderService).to receive(:call)
          .and_raise(ShoppingBaskets::CheckoutOrderService::PaymentError.new("Insufficient funds"))
      end

      it "does not persist the Address" do
        expect {
          post endpoint, params: valid_params, headers: headers
        }.to change(Address, :count).by 0
      end

      it "does not persist the CreditCard" do
        expect {
          post endpoint, params: valid_params, headers: headers
        }.to change(CreditCard, :count).by 0
      end

      it "returns 402 Payment Required" do
        post endpoint, params: valid_params, headers: headers
        expect(response).to have_http_status(:payment_required)
      end
    end

    context "Error Handling" do
      it "returns 422 with correct JSON structure when Basket is Empty" do
        allow(ShoppingBaskets::CheckoutOrderService).to receive(:call)
          .and_raise(ShoppingBaskets::CheckoutOrderService::EmptyBasketError.new("Basket is empty"))

        post endpoint, params: valid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq 422
        expect(json["error"]["messages"]).to include("Basket is empty")
      end

      it "returns 400 Bad Request if params are missing" do
        invalid_params = { payment_token: payment_token }

        post endpoint, params: invalid_params, headers: headers

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
