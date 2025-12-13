require "rails_helper"

RSpec.describe ShoppingBaskets::UpdateBasketItemService do
  let(:basket)  { create(:shopping_basket) }
  let(:product) { create(:product, stock: 10) }

  subject(:call_service) do
    described_class.call(
      shopping_basket: basket,
      product_id: product.id,
      quantity: quantity
    )
  end

  describe "#call" do
    context "when quantity is positive (> 0)" do
      let(:quantity) { 3 }

      it "creates a new item if it does not exist" do
        expect { call_service }.to change(ShoppingBasketProduct, :count).by 1

        item = basket.shopping_basket_products.last
        expect(item.product).to eq product
        expect(item.quantity).to eq 3
      end

      it "updates the quantity if the item already exists" do
        create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 1)

        expect { call_service }.not_to change(ShoppingBasketProduct, :count)

        expect(basket.shopping_basket_products.first.quantity).to eq 3
      end

      it "raises an error if there is not enough stock" do
        service_excess = described_class.new(
          shopping_basket: basket, product_id: product.id, quantity: 20
        )

        expect { service_excess.call }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "locks the product to prevent race conditions" do
        allow(Product).to receive(:find).with(product.id).and_return product
        expect(product).to receive(:with_lock).and_yield

        call_service
      end
    end

    context "when quantity is zero" do
      let!(:item) { create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 5) }

      context "with quantity 0" do
        let(:quantity) { 0 }

        it "removes the item from the basket" do
          expect { call_service }.to change(ShoppingBasketProduct, :count).by(-1)
          expect(ShoppingBasketProduct.exists?(item.id)).to be_falsey
        end
      end

      context "when item does not exist" do
        let(:quantity) { 0 }

        before { item.destroy }

        it "does not raise error and does nothing" do
          expect { call_service }.not_to change(ShoppingBasketProduct, :count)
        end
      end
    end

    describe "Return Value" do
      let(:quantity) { 2 }

      it "returns the reloaded shopping basket using the optimized scope" do
        expect(ShoppingBasket).to receive(:with_associations).and_call_original

        result = call_service

        expect(result).to be_a ShoppingBasket
        expect(result.id).to eq basket.id

        expect(result.shopping_basket_products.first.quantity).to eq 2
      end
    end
  end
end
