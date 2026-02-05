module Api
  module V1
    class ProductsController < BaseController
      def index
        # 1. Prepare query and paginate (lazy load)
        pagy_page = [ index_params[:page].to_i, 1 ].max
        products_query = Product.order(id: :asc)
        @pagy, @records = pagy(products_query, page: pagy_page)

        # 2. Derive cache versions (avoids full serialization if stale)
        # Triggers a fast `SELECT MAX(updated_at)` specific to this page window.
        max_updated_at = @records.maximum(:updated_at)

        # 3. HTTP Cache check (returns 304 if client matches ETag/Last-Modified)
        if stale?(etag: @records, last_modified: max_updated_at)

          # 4. Server Cache
          cache_key = [ "products_index", pagy_page, max_updated_at ]

          data = Rails.cache.fetch(cache_key) do
            PaginationBlueprint.render_as_hash(
              @pagy,
              records: ProductBlueprint.render_as_hash(@records)
            )
          end

          render status: :ok, json: data
        end
      end

      def show
        product = Product.find(params[:id])

        if stale?(product)
          product_blueprint = Rails.cache.fetch(product.cache_key_with_version) do
            ProductBlueprint.render_as_hash(product)
          end

          render status: :ok, json: product_blueprint
        end
      end

      private

      def index_params
        params.permit(:page)
      end
    end
  end
end
