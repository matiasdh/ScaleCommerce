module Api
  module V1
    class ShoppingBasketsController < BaseController
      before_action :set_shopping_basket, only: :show

      def show
        # Calculate cache key including the max product updated_at, if it is nil, it works well too.
        # This ensures the cache is invalidated if the basket changes OR if a product's stock updates.
        stale_key = [ current_shopping_basket, current_shopping_basket.products_last_updated_at ]
        cache_key = [ current_shopping_basket.cache_key_with_version,
          current_shopping_basket.products_last_updated_at ]

        # Fetch data or generate it
        if stale?(etag: stale_key)
          basket_blueprint = Rails.cache.fetch(cache_key) do
            ShoppingBasketBlueprint.render_as_hash(current_shopping_basket)
          end

          render status: :ok, json: basket_blueprint
        end
      end
    end
  end
end
