module ShoppingBasketAuth
  extend ActiveSupport::Concern

  included do
    attr_reader :current_shopping_basket
  end

  private

  # Loads the shopping basket into memory if it exists,
  # otherwise instantiates a new one (without persisting it).
  def set_shopping_basket
    token = request.headers["Authorization"]&.split(" ")&.last
    @current_shopping_basket = ShoppingBasket.with_associations.find_by(uuid: token) || ShoppingBasket.new
  end

  # Ensures there is a persisted shopping basket:
  # - If one exists, it is loaded into memory.
  # - If not, a new basket is created and its UUID is returned in the headers.
  def ensure_shopping_basket
    set_shopping_basket

    if @current_shopping_basket.new_record?
      @current_shopping_basket.save!
      response.headers["Shopping-Basket-ID"] = @current_shopping_basket.uuid
    end
  end
end
