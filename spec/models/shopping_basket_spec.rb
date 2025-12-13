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
        it 'does not overwrite the provided UUID' do
          basket = build :shopping_basket, uuid: "TEST-UUID-V7"

          expect(basket.uuid).to eq("TEST-UUID-V7")
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

  describe '#total_price' do
    context 'when the basket is empty' do
      it 'returns zero' do
        expect(subject.total_price.cents).to eq(0)
      end
    end

    context 'when the basket has products' do
      let(:product_1) { create(:product, price_cents: 100_00) }
      let(:product_2) { create(:product, price_cents: 150_00) }

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
