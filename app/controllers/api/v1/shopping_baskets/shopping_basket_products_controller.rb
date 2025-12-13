module Api
  module V1
    module ShoppingBaskets
      class ShoppingBasketProductsController < BaseController
        before_action :ensure_shopping_basket, only: [ :create ]

        def create
          updated_basket = ::ShoppingBaskets::UpdateBasketItemService.call(
            shopping_basket: current_shopping_basket,
            product_id: product_params[:product_id],
            quantity: product_params[:quantity]
          )

          render json: ShoppingBasketBlueprint.render(updated_basket), status: :created
        end

        private

        def product_params
          params.require(:product).permit(:product_id, :quantity)
        end
      end
    end
  end
end
