require 'rails_helper'

RSpec.describe OrderProduct, type: :model do
  subject { build(:order_product) }

  describe "Associations" do
    it { should belong_to(:order) }
    it { should belong_to(:product) }
  end

  describe "Validations" do
    it { is_expected.to validate_uniqueness_of(:product_id).scoped_to(:order_id) }

    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }

    it { should validate_presence_of(:unit_price_cents) }
  end

  describe "Monetize" do
    it { is_expected.to monetize(:unit_price).with_model_currency(:unit_price_currency) }
    it { is_expected.to validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:name).to(:product) }
    it { is_expected.to delegate_method(:description).to(:product) }
  end

  describe "#total_price" do
    it "calculates the total price based on quantity and unit price" do
      item = build(:order_product, quantity: 5, unit_price_cents: 2000)

      expect(item.total_price.cents).to eq(10000)
    end
  end
end
