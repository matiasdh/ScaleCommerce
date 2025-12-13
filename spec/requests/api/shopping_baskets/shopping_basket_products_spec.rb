require 'rails_helper'

RSpec.describe "Api::V1::ShoppingBaskets::ShoppingBasketProducts", type: :request do
  let(:product) { create(:product, stock: 10) }
  let(:base_url) { "/api/v1/shopping_basket/products" }

  let(:valid_params) do
    {
      product: {
        product_id: product.id,
        quantity: 2
      }
    }
  end

  describe "POST /api/v1/shopping_basket/products" do
    context "when the user is a new guest (no Authorization header)" do
      subject(:make_request) { post base_url, params: valid_params, as: :json }

      it "creates a new shopping basket in the database" do
        expect { make_request }.to change(ShoppingBasket, :count).by(1)
      end

      it "returns a 201 Created status with the correct product data" do
        make_request

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["products"].size).to eq(1)
        expect(json["products"].first["id"]).to eq(product.id)
      end

      it "returns the new basket UUID in the headers" do
        make_request

        expect(response.headers["Shopping-Basket-ID"]).to be_present
      end
    end

    context "when the user returns (with Authorization header)" do
      let!(:basket) { create(:shopping_basket) }
      let(:headers) { { "Authorization" => "Bearer #{basket.uuid}" } }

      it "adds the product to the existing basket" do
        expect {
          post base_url, params: valid_params, headers: headers, as: :json
        }.not_to change(ShoppingBasket, :count)

        expect(response).to have_http_status(:created)

        expect(basket.shopping_basket_products.count).to eq(1)
        expect(basket.shopping_basket_products.first.product).to eq(product)
      end

      it "updates quantity if the product was already in the basket" do
        create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 1)

        update_params = { product: { product_id: product.id, quantity: 5 } }

        post base_url, params: update_params, headers: headers, as: :json

        expect(response).to have_http_status(:created)
        expect(basket.shopping_basket_products.first.reload.quantity).to eq(5)
      end
    end

    context "error handling" do
      it "returns 404 if the product does not exist" do
        invalid_params = { product: { product_id: "wrong_id", quantity: 1 } }

        post base_url, params: invalid_params, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it "returns 400 (Bad Request) if params are missing" do
        post base_url, params: {}, as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it "returns 422 if stock validation fails" do
        excess_params = { product: { product_id: product.id, quantity: 20 } }

        post base_url, params: excess_params, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["error"]).to include({
          "code" => 422,
          "messages" => [ "Quantity exceeds available stock." ]
        })
      end
    end
  end
end
