module Api
  module V1
    class ShoppingBasketsController < BaseController
      before_action :set_shopping_basket, only: :show

      def show
        render status: :ok, json: ShoppingBasketBlueprint.render(current_shopping_basket)
      end
    end
  end
end
