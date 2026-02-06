module Api
  module V2
    class ProductsController < BaseController
      def index
        @pagy, @records = pagy(Product.order(id: :asc), page: index_params[:page], paginator: :keyset)
        max_updated_at = @records.map(&:updated_at).max # Loaded into memory

        cached_render(
          stale_key: [ @records, max_updated_at ],
          cache_key: [ "v2/products", index_params[:page], max_updated_at ]
        ) do
          ::V2::PaginationBlueprint.render_as_hash(@pagy, records: ProductBlueprint.render_as_hash(@records))
        end
      end

      def show
        product = Product.find(params[:id])

        cached_render(stale_key: product, cache_key: product.cache_key_with_version) do
          ProductBlueprint.render_as_hash(product)
        end
      end

      private

      def index_params
        params.permit(:page)
      end
    end
  end
end
