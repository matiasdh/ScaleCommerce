require "rails_helper"

RSpec.describe "Api::V2::ShoppingBaskets", type: :request do
  describe "GET /api/v2/shopping_basket" do
    let(:headers) { {} }
    subject(:make_request) { get "/api/v2/shopping_basket", headers: headers }

    context "when the basket is empty" do
      it "returns a successful response" do
        make_request
        expect(response).to have_http_status(:ok)
      end

      it "returns the correctly serialized shopping basket" do
        make_request
        json_response = JSON.parse(response.body)

        expect(json_response).to eq({ "products" => [], "total_price" => { "cents" => 0, "currency" => "USD" } })
      end

      it "does not persist the basket to the database" do
        expect { make_request }.not_to change(ShoppingBasket, :count)
      end
    end

    context "when the basket has products" do
      let!(:basket) { create(:shopping_basket, :with_products, products_count: 1) }
      let(:headers) { { "Authorization" => "Bearer #{basket.uuid}" } }

      let(:basket_item) { basket.shopping_basket_products.first }
      let(:product)     { basket_item.product }

      it "returns the products list" do
        make_request
        json_response = JSON.parse(response.body)

        expect(json_response["products"]).to be_an(Array)
        expect(json_response["products"].size).to eq(1)

        item = json_response["products"].first

        expect(item["id"]).to eq product.id
        expect(item["quantity"]).to eq basket_item.quantity
        expect(item["name"]).to eq product.name
        expect(item["total_price"]).to eq({
          "cents" => product.price.cents * basket_item.quantity,
          "currency" => "USD"
        })
      end

      it "returns the calculated total price" do
        make_request
        json_response = JSON.parse(response.body)

        expected_total = basket.shopping_basket_products.sum(&:total_price)

        expect(json_response["total_price"]).to eq({
          "cents" => expected_total.cents,
          "currency" => "USD"
        })
      end
    end
  end
end
