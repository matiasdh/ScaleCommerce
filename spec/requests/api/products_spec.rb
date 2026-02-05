# spec/requests/api/products_spec.rb
require "rails_helper"

RSpec.describe "Api::Products", type: :request do
  describe "GET /api/v1/products" do
    let!(:default_products) { create_list(:product, 25) }

    it "delegates serialization to ProductBlueprint and PaginationBlueprint" do
      # We just want to spy on calls, not change behavior
      allow(ProductBlueprint).to receive(:render_as_hash).and_call_original
      allow(PaginationBlueprint).to receive(:render_as_hash).and_call_original

      get "/api/v1/products", params: { page: 1 }

      expect(ProductBlueprint).to have_received(:render_as_hash)

      expect(PaginationBlueprint).to have_received(:render_as_hash)
    end

    it "returns HTTP 200 and correct pagination metadata structure" do
      get "/api/v1/products", params: { page: 1 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body).with_indifferent_access

      expect(json).to include(:page, :record_count, :pages, :per_page, :records)

      expect(json[:records]).to be_an(Array)
      expect(json[:records].first).to include(:id, :name)
      expect(json[:records].size).to eq(20) # Default limit
    end

    context "when requesting page 2 to test slicing logic" do
      before { get "/api/v1/products", params: { page: 2 } }

      it "returns the correct metadata for the last page" do
        json = JSON.parse(response.body).with_indifferent_access

        expect(json[:page]).to eq(2)
        expect(json[:record_count]).to eq(25)
        expect(json[:per_page]).to eq(20)
        expect(json[:pages]).to eq(2)
      end

      it "returns only the remaining records (5 items) and validates their IDs" do
        json = JSON.parse(response.body).with_indifferent_access

        expect(json[:records].size).to eq(5)

        expect(json[:records].map { |p| p[:id] })
          .to match_array(default_products.last(5).map(&:id))
      end
    end
  end

  describe "GET /api/products/:id" do
    let!(:product) { create(:product, stock: 0, currency: "USD", price_cents: 1000) }

    context "when the product exists" do
      before { get "/api/v1/products/#{product.id}" }

      it "returns status 200 and the product serialized with correct attributes" do
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body).with_indifferent_access

        expect(json).to include(
          id: product.id,
          name: product.name,
          stock_status: Product::STOCK_STATUS_OUT
        )

        expect(json[:price]).to include(
          cents: 1000,
          currency: "USD"
        )
      end
    end

    context "when the product does not exist" do
      before do
        get "/api/v1/products/not_found_wrong_id"
      end

      it "returns 404 Not Found" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns the error in the correct JSON format" do
        json_response = JSON.parse(response.body)

        # Verificamos tu estructura exacta
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
