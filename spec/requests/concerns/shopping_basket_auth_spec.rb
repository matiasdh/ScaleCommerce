require "rails_helper"

RSpec.describe "ShoppingBasketAuth concern", type: :request do
  class DummyController < ApplicationController
    include ShoppingBasketAuth

    before_action :set_shopping_basket, only: :passive_check
    before_action :ensure_shopping_basket, only: :active_check

    def passive_check
      render_state
    end

    def active_check
      render_state
    end

    private

    def render_state
      render json: {
        uuid: current_shopping_basket.uuid,
        is_persisted: current_shopping_basket.persisted?
      }
    end
  end

  before do
    Rails.application.routes.draw do
      get  "/test_passive", to: "dummy#passive_check"
      post "/test_active",  to: "dummy#active_check"
    end
  end

  after do
    Rails.application.reload_routes!
  end

  let(:json) { JSON.parse(response.body) }
  let(:uuid) { json["uuid"] }
  let(:persisted) { json["is_persisted"] }

  describe "passive mode (read-only)" do
    it "creates in-memory basket for new users" do
      expect { get "/test_passive" }.not_to change(ShoppingBasket, :count)
      expect(uuid).to be_present
      expect(persisted).to be false
    end

    it "loads existing basket for valid token" do
      basket = ShoppingBasket.create!
      get "/test_passive", headers: { "Authorization" => "Bearer #{basket.uuid}" }
      expect(uuid).to eq(basket.uuid)
      expect(persisted).to be true
    end

    it "falls back to new in-memory for invalid token" do
      get "/test_passive", headers: { "Authorization" => "Bearer invalid-token" }
      expect(uuid).not_to eq("invalid-token")
      expect(persisted).to be false
    end
  end

  describe "active mode (write/ensure)" do
    it "persists new basket and sets header for new users" do
      expect { post "/test_active" }.to change(ShoppingBasket, :count).by(1)
      expect(response.headers["Shopping-Basket-ID"]).to eq(uuid)
      expect(persisted).to be true
    end

    it "recreates basket and sets header for invalid token" do
      post "/test_active", headers: { "Authorization" => "Bearer invalid" }
      expect(response.headers["Shopping-Basket-ID"]).to eq(uuid)
      expect(uuid).not_to eq("invalid")
    end

    context "when a valid token is provided" do
      let!(:basket) { ShoppingBasket.create! }
      let(:headers) { { "Authorization" => "Bearer #{basket.uuid}" } }

      it "loads existing basket for valid token" do
        get "/test_passive", headers: headers
        expect(uuid).to eq(basket.uuid)
        expect(persisted).to be true
      end

      it "eager loads products to prevent N+1 queries" do
        expect(ShoppingBasket).to receive(:with_associations)
          .and_call_original

        get "/test_passive", headers: headers
      end
    end
  end
end
