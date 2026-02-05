require 'rails_helper'

RSpec.describe ShoppingBasketProduct, type: :model do
  subject { create(:shopping_basket_product) }

  it "is valid with a factory" do
    expect(subject).to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:shopping_basket) }
    it { is_expected.to belong_to(:product) }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:product_id).scoped_to(:shopping_basket_id) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
  end

  describe 'delegations' do
    # Shoulda Matchers makes this one-liner possible
    it { is_expected.to delegate_method(:name).to(:product) }
    it { is_expected.to delegate_method(:description).to(:product) }
  end

  describe '#total_price' do
    let(:product) { build(:product, price: 100.0) }
    subject { build(:shopping_basket_product, product: product, quantity: 3) }

    it 'calculates the total price based on quantity and product price' do
      expect(subject.total_price.cents).to eq 300_00
    end

    it 'returns zero if quantity is zero (edge case)' do
      subject.quantity = 0
      expect(subject.total_price).to eq 0
    end
  end

  describe '#stock_status' do
    let(:product) { create(:product, stock: 10) }
    subject!(:basket_item) { create(:shopping_basket_product, product: product, quantity: 5) }

    context "when product has enough stock" do
      it "returns available status" do
        expect(basket_item.stock_status).to eq(Product::STOCK_STATUS_AVAILABLE)
      end
    end

    context "when product stock drops below requested quantity" do
      before do
        product.update!(stock: 2)
      end

      it "returns out of stock status" do
        expect(basket_item.reload.stock_status).to eq(Product::STOCK_STATUS_OUT)
      end
    end

    context "when product stock matches requested quantity exactly" do
      before do
        product.update!(stock: 5)
      end

      it "returns available status" do
        expect(basket_item.reload.stock_status).to eq(Product::STOCK_STATUS_AVAILABLE)
      end
    end
  end
end
