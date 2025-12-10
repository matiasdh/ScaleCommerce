require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { build(:product) }

  it "is valid with a factory" do
    expect(subject).to be_valid
  end

  describe "Constants" do
    it "defines STOCK_STATUS_OUT with the correct value" do
      expect(Product::STOCK_STATUS_OUT).to eq "OUT_OF_STOCK"
    end

    it "defines STOCK_STATUS_AVAILABLE with the correct value" do
      expect(Product::STOCK_STATUS_AVAILABLE).to eq "AVAILABLE"
    end
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:currency) }

    describe "stock validation" do
      it { is_expected.to validate_presence_of(:stock) }
      it { is_expected.to validate_numericality_of(:stock).only_integer }
      it { is_expected.to validate_numericality_of(:stock).is_greater_than_or_equal_to 0 }
    end

    describe "price_cents validation" do
      it { is_expected.to validate_presence_of(:price_cents) }
      it { is_expected.to validate_numericality_of(:price_cents).only_integer }
    end
  end

  describe "Monetize" do
    it { is_expected.to monetize(:price).with_model_currency(:currency) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than 0 }
  end

  describe "#stock_status" do
    let(:product_available) { build(:product) }
    let(:product_out) { build(:product, :out_of_stock) }

    context "when stock is greater than zero" do
      it "returns 'AVAILABLE'" do
        expect(product_available.stock_status).to eq Product::STOCK_STATUS_AVAILABLE
      end
    end

    context "when stock is zero" do
      it "returns 'OUT_OF_STOCK'" do
        expect(product_out.stock_status).to eq Product::STOCK_STATUS_OUT
      end
    end
  end
end
