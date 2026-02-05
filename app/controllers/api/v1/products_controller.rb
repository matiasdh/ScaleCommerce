module Api
  module V1
    class ProductsController < BaseController
      def index
        pagy_page = index_params[:page].present? ? index_params[:page].to_i : 1
        @pagy, @records = pagy(
          Product.order(id: :asc),
          page: pagy_page,
        )
        render status: :ok,
          json: PaginationBlueprint.render(
              @pagy,
              records: ProductBlueprint.render_as_hash(@records)
            )
      end

      def show
        product = Product.find(params[:id])
        render status: :ok, json: ProductBlueprint.render(product)
      end

      private

      def index_params
        params.permit(:page)
      end
    end
  end
end
