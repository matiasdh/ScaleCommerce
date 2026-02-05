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

  describe '#products_last_updated_at' do
    context 'when the basket is empty' do
      it 'returns nil' do
        expect(subject.products_last_updated_at).to be_nil
      end
    end

    context 'when the basket has products' do
      let(:old_time) { Time.zone.parse('2023-01-01 10:00:00') }
      let(:new_time) { Time.zone.parse('2023-01-01 12:00:00') }
      let(:product_1) { create(:product, updated_at: old_time) }
      let(:product_2) { create(:product, updated_at: new_time) }

      before do
        create(:shopping_basket_product, shopping_basket: subject, product: product_1)
        create(:shopping_basket_product, shopping_basket: subject, product: product_2)
      end

      it 'returns the maximum updated_at of the products' do
        expect(subject.products_last_updated_at.to_i).to eq(new_time.to_i)
      end
    end
  end

  describe 'performance' do
    describe '#products_last_updated_at' do
      let(:basket) { create(:shopping_basket) }
      let(:products) { create_list(:product, 3) }

      before do
        products.each do |product|
          create(:shopping_basket_product, shopping_basket: basket, product: product)
        end
      end

      it 'avoids N+1 queries by eager loading associations' do
        shopping_basket_with_associations = described_class.with_associations.find(basket.id)

        expect(shopping_basket_with_associations.association(:shopping_basket_products)).to be_loaded

        shopping_basket_with_associations.shopping_basket_products.each do |sb_product|
          expect(sb_product.association(:product)).to be_loaded
        end

        expect(shopping_basket_with_associations.products_last_updated_at).to be_present
      end
    end
  end
end
