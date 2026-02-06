require "rails_helper"

RSpec.describe "Api::V2::Products", type: :request do
  describe "GET /api/v2/products" do
    let!(:default_products) { create_list(:product, 25) }

    it "delegates serialization to ProductBlueprint and V2::PaginationBlueprint" do
      allow(ProductBlueprint).to receive(:render_as_hash).and_call_original
      allow(::V2::PaginationBlueprint).to receive(:render_as_hash).and_call_original

      get "/api/v2/products"

      expect(ProductBlueprint).to have_received(:render_as_hash)
      expect(::V2::PaginationBlueprint).to have_received(:render_as_hash)
    end

    it "returns HTTP 200 and correct pagination metadata structure (no totals)" do
      get "/api/v2/products"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      # V2: Keyset pagination
      expect(json).to include("per_page", "next", "previous", "records")
      expect(json).to_not include("record_count", "pages", "page")

      expect(json["records"]).to be_an(Array)
      expect(json["records"].first).to include("id", "name")
      expect(json["records"].size).to eq(20)
    end

    context "when requesting page 2 via keyset pagination" do
      let(:first_page_key) do
        get "/api/v2/products"
        JSON.parse(response.body)["next"]
      end

      before { get "/api/v2/products", params: { page: first_page_key } }

      it "returns the correct metadata for the last page" do
        json = JSON.parse(response.body)

        expect(json["per_page"]).to eq(20)
        expect(json["next"]).to be_nil # No more pages
      end

      it "returns only the remaining records (5 items) and validates their IDs" do
        json = JSON.parse(response.body)

        expect(json["records"].size).to eq(5)

        expect(json["records"].map { |p| p["id"] })
          .to match_array(default_products.last(5).map(&:id))
      end
    end
  end

  describe "GET /api/v2/products/:id" do
    let!(:product) { create(:product, stock: 0, currency: "USD", price_cents: 1000) }

    context "when the product exists" do
      before { get "/api/v2/products/#{product.id}" }

      it "returns status 200 and the product serialized with correct attributes" do
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)

        expect(json).to include(
          "id" => product.id,
          "name" => product.name,
          "stock_status" => Product::STOCK_STATUS_OUT
        )

        expect(json["price"]).to include(
          "cents" => 1000,
          "currency" => "USD"
        )
      end
    end

    context "when the product does not exist" do
      before { get "/api/v2/products/not_found_wrong_id" }

      it "returns 404 Not Found" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns the error in the correct JSON format" do
        json_response = JSON.parse(response.body)

        expect(json_response).to match({
          "error" => {
            "code" => 404,
            "messages" => [ "Couldn't find Product with 'id'=\"not_found_wrong_id\"" ]
          }
        })
      end
    end
  end
end
