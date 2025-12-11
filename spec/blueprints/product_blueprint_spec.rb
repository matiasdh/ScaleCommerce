# spec/blueprints/product_blueprint_spec.rb
require "rails_helper"

RSpec.describe ProductBlueprint do
  describe ".render_as_hash" do
    subject(:result) { described_class.render_as_hash(product) }
    let(:product) { create :product }

    it "serializes the basic fields" do
      expect(result).to include(
        id: product.id,
        name: product.name,
        description: product.description,
        stock_status: product.stock_status
      )
    end

    it "serializes the price using MoneyBlueprint" do
      expect(result[:price]).to eq(
        cents: product.price_cents,
        currency: product.currency
      )
    end
  end
end
