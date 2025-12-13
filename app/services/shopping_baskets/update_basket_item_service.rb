module ShoppingBaskets
  class UpdateBasketItemService < BaseService
    def initialize(shopping_basket:, product_id:, quantity:)
      @shopping_basket = shopping_basket
      @product_id = product_id
      @quantity = quantity.to_i
    end

    def call
      update_or_delete_item
      ShoppingBasket.with_associations.find(@shopping_basket.id)
    end

    private

    def update_or_delete_item
      return remove_item if @quantity == 0

      product = Product.find(@product_id)

      product.with_lock do
        item = @shopping_basket.shopping_basket_products.find_or_initialize_by(product: product)
        item.quantity = @quantity
        item.save!
      end
    end

    def remove_item
      item = @shopping_basket.shopping_basket_products.find_by(product_id: @product_id)
      item&.destroy!
    end
  end
end
