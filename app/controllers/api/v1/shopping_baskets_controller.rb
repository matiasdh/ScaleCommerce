module Api
  module V1
    class ShoppingBasketsController < BaseController
      def show
        shopping_basket = ShoppingBasket.new
        render status: :ok, json: ShoppingBasketBlueprint.render(shopping_basket)
      end
    end
  end
end
