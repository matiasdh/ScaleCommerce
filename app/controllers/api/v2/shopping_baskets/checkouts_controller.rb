module Api
  module V2
    module ShoppingBaskets
      class CheckoutsController < BaseController
        before_action :ensure_shopping_basket, only: [ :create ]

        def create
          return render_checkout_already_processing if current_shopping_basket.order.present?

          current_shopping_basket.build_order(status: :pending).save!
          enqueue_checkout_job
          render json: checkout_response, status: :accepted
        rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
          render_checkout_already_processing
        end

        private

        def enqueue_checkout_job
          CheckoutOrderJob.perform_later(
            shopping_basket_id: current_shopping_basket.id,
            email: checkout_params[:email],
            payment_token: checkout_params[:payment_token],
            address_params: address_params.to_h
          )
        end

        def render_checkout_already_processing
          render json: {
            error: {
              code: 409,
              messages: [ "Checkout is already being processed" ]
            }
          }, status: :conflict
        end

        def checkout_response
          {
            message: "Checkout processing started",
            notifications: {
              channel: "CheckoutNotificationsChannel",
              params: { shopping_basket_id: current_shopping_basket.uuid }
            }
          }
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
