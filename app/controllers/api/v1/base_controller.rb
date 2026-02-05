module Api
  module V1
    class BaseController < ApplicationController
      include Pagy::Method
      include ShoppingBasketAuth

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
      rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
      rescue_from ::ShoppingBaskets::CheckoutOrderService::EmptyBasketError, with: :handle_empty_basket
      rescue_from ::ShoppingBaskets::CheckoutOrderService::PaymentError, with: :handle_payment_error

      private

      def render_not_found(exception)
        render json: {
          error: {
            code: 404,
            messages: [ exception.message ]
          }
        }, status: :not_found
      end

      def render_record_invalid(exception)
        render json: {
          error: {
            code: 422,
            messages: exception.record.errors.full_messages
          }
        }, status: :unprocessable_content
      end

      def render_parameter_missing(exception)
        render json: {
          error: {
            code: 400,
            messages: [ "Missing parameter: #{exception.param}" ]
          }
        }, status: :bad_request
      end

      def handle_empty_basket(exception)
        render json: {
          error: {
            code: 422,
            messages: [ exception.message ]
          }
        }, status: :unprocessable_content
      end

      def handle_payment_error(exception)
        render json: {
          error: {
            code: 402,
            messages: [ exception.message ]
          }
        }, status: :payment_required
      end
    end
  end
end
