require 'rails_helper'

RSpec.describe ShoppingBasket, type: :model do
  subject { build(:shopping_basket) }

  it "is valid with a factory" do
    expect(subject).to be_valid
  end

  describe 'callbacks' do
    describe '#set_uuid' do
      context 'when a new record is initialized' do
        it 'automatically generates a UUID v7' do
          expect(subject.uuid).to be_a_uuid.of_version(7)
        end
      end

      context 'when a UUID is provided manually' do
        let(:provided_uuid) { "019c2f4e-c385-7a57-a59c-b7adb9ffa4c2" }
        it 'does not overwrite the provided UUID' do
          basket = build :shopping_basket, uuid: provided_uuid

          expect(basket.uuid).to eq provided_uuid
        end
      end
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:shopping_basket_products).dependent(:destroy) }
    it { is_expected.to have_many(:products).through(:shopping_basket_products) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:uuid) }
  end

  describe 'scope .with_associations' do
    let!(:basket) { create(:shopping_basket, :with_products) }

    it 'eager loads shopping_basket_products and their nested products' do
      record = described_class.with_associations.find(basket.id)

      expect(record.association(:shopping_basket_products)).to be_loaded
      record.shopping_basket_products.each do |shopping_basket_product|
        expect(shopping_basket_product.association(:product)).to be_loaded
      end
    end
  end

  describe '#total_price' do
    context 'when the basket is empty' do
      it 'returns zero' do
        expect(subject.total_price.cents).to eq(0)
      end
    end

    context 'when the basket has products' do
      let(:product_1) { create(:product, price_cents: 100_00, stock: 10) }
      let(:product_2) { create(:product, price_cents: 150_00, stock: 5) }

      before do
        create(:shopping_basket_product, shopping_basket: subject, product: product_1, quantity: 2)
        create(:shopping_basket_product, shopping_basket: subject, product: product_2, quantity: 1)
      end

      it 'calculates the sum of all line items' do
        expect(subject.total_price.cents).to eq(350_00) # 100 * 2 + 150 * 1 = 350
      end
    end
  end
end
