require 'rails_helper'

RSpec.describe "Caching", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  # Shared examples to test ETag and Last-Modified headers
  shared_examples "an endpoint with ETag support" do |path_proc|
    it "returns ETag and Last-Modified headers" do
      get path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.headers['ETag']).to be_present
      expect(response.headers['Last-Modified']).to be_present
    end

    it "returns 304 Not Modified when client sends valid cache headers" do
      # 1. First request to get headers
      get path, headers: headers
      etag = response.headers['ETag']
      last_modified = response.headers['Last-Modified']

      # 2. Second request with conditional headers
      get path, headers: headers.merge({ 'If-None-Match' => etag, 'If-Modified-Since' => last_modified })
      expect(response).to have_http_status(:not_modified)
    end
  end

  describe "api/v1/products" do
    let!(:product) { create(:product, updated_at: 1.hour.ago) }
    let(:headers) { {} }

    describe "GET /api/v1/products" do
      let(:path) { "/api/v1/products" }
      it_behaves_like "an endpoint with ETag support"
    end

    describe "GET /api/v1/products/:id" do
      let(:path) { "/api/v1/products/#{product.id}" }
      it_behaves_like "an endpoint with ETag support"
    end
  end

  describe "api/v1/shopping_basket" do
    let(:shopping_basket) { create(:shopping_basket) }
    let(:headers) { { "Authorization" => "Bearer #{shopping_basket.uuid}" } }
    let!(:product_for_basket) { create(:product, stock: 10, updated_at: 1.hour.ago) }

    before do
      create(:shopping_basket_product, shopping_basket: shopping_basket, product: product_for_basket, quantity: 1)
    end

    it "changes the response ETag (invalidating cache) when a product is updated" do
      # 1. Initial Request
      get "/api/v1/shopping_basket", headers: headers
      initial_etag = response.headers['ETag']

      # 2. Modify state (Simulate update after some time)
      travel 10.minutes do
        product_for_basket.touch # Updates updated_at

        # 3. Request again
        get "/api/v1/shopping_basket", headers: headers
        new_etag = response.headers['ETag']

        expect(new_etag).not_to eq(initial_etag)
        expect(response).to have_http_status(:ok) # Should be 200 (fresh content), not 304
      end
    end
  end
end
