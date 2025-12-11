module Api
  module V1
    module ShoppingBaskets
      class CheckoutsController < BaseController
        before_action :ensure_shopping_basket, only: [ :create ]

        def create
          order = ::ShoppingBaskets::CheckoutOrderService.call(
            shopping_basket: current_shopping_basket,
            email: checkout_params[:email],
            payment_token: checkout_params[:payment_token],
            address_params: address_params
          )

          order_with_products = Order.with_associations.find(order.id)
          render json: OrderBlueprint.render(order_with_products), status: :created
        end

        def checkout_params
          params.permit(:payment_token, :email)
        end

        def address_params
          params.require(:address).permit(:line_1, :line_2, :city, :state, :zip, :country)
        end
      end
    end
  end
end
