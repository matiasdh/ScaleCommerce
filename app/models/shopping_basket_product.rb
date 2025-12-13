class ShoppingBasketProduct < ApplicationRecord
  belongs_to :shopping_basket
  belongs_to :product

  validates :product_id,
            uniqueness: { scope: :shopping_basket_id }
  validates :quantity,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  delegate :name, :description, :stock_status, to: :product

  def total_price
    product.price * quantity
  end
end
