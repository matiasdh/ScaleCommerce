module Api
  module V1
    module ShoppingBaskets
      class CheckoutsController < BaseController
        before_action :ensure_shopping_basket, only: [ :create ]

        def create
          # Use a transaction so no credit cards or addresses are persisted if the checkout fails
          # Note: The PaymentGateway is handled inside the transaction, so it adds latency to the checkout process
          # For future iterations, we could move the payment processing ouside the transaction
          # and use order states to handle the different states of the orders and the checkout process
          order = ActiveRecord::Base.transaction do
            credit_card = CreditCard.create_from_token! checkout_params[:payment_token]
            address = Address.create address_params

            ::ShoppingBaskets::CheckoutOrderService.call(
              shopping_basket: current_shopping_basket,
              email: checkout_params[:email],
              credit_card: credit_card,
              address: address
            )
          end

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
