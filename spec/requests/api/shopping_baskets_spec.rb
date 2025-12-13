require "rails_helper"

RSpec.describe "Api::ShoppingBaskets", type: :request do
  describe "GET /api/v1/shopping_basket" do
    subject(:make_request) { get "/api/v1/shopping_basket" }

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
      let(:product) { create(:product, price_cents: 100_00, name: "Gamer Mouse") }
      let(:basket_with_items) { create(:shopping_basket) }

      before do
        create(:shopping_basket_product, shopping_basket: basket_with_items, product: product, quantity: 2)
        # TODO: Use UUID Headers after implementation
        allow(ShoppingBasket).to receive(:new).and_return(basket_with_items)
      end

      it "returns the products list" do
        make_request
        json_response = JSON.parse(response.body)

        expect(json_response["products"]).to be_an(Array)
        expect(json_response["products"].size).to eq(1)

        item = json_response["products"].first

        expect(item["id"]).to eq(product.id)
        expect(item["quantity"]).to eq(2)
        expect(item["name"]).to eq("Gamer Mouse")
        expect(item["total_price"]).to eq({
          "cents" => 200_00, # 100_00 * 2
          "currency" => "USD"
        })
      end

      it "returns the calculated total price" do
        make_request
        json_response = JSON.parse(response.body)

        expect(json_response["total_price"]).to eq({
          "cents" => 200_00, # 100_00 * 2
          "currency" => "USD"
        })
      end
    end
  end
end
