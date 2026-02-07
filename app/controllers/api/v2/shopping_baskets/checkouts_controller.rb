module Api
  module V2
    module ShoppingBaskets
      class CheckoutsController < BaseController
        before_action :ensure_shopping_basket, only: [ :create ]

        def create
          CheckoutOrderJob.perform_later(
            shopping_basket_id: current_shopping_basket.id,
            email: checkout_params[:email],
            payment_token: checkout_params[:payment_token],
            address_params: address_params.to_h
          )

          render json: { message: "Checkout processing started" }, status: :accepted
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
