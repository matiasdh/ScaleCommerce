class ShoppingBasketProduct < ApplicationRecord
  belongs_to :shopping_basket
  belongs_to :product

  validates :product_id,
            uniqueness: { scope: :shopping_basket_id }
  validates :quantity,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validate :stock_availability, if: :quantity_changed?

  delegate :name, :description, :stock_status, to: :product

  def total_price
    product.price * quantity
  end

  private

  def stock_availability
    return unless product && quantity

    errors.add(:quantity, "exceeds available stock.") if quantity > product.stock
  end
end
