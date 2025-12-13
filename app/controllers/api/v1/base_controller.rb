module Api
  module V1
    class BaseController < ApplicationController
      include Pagy::Method
      include ShoppingBasketAuth

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      private

      def render_not_found(exception)
        render json: {
          error: {
            code: 404,
            message: exception.message
          }
        }, status: :not_found
      end
    end
  end
end
