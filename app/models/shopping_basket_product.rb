class ShoppingBasketProduct < ApplicationRecord
  belongs_to :shopping_basket
  belongs_to :product

  validates :product_id,
            uniqueness: { scope: :shopping_basket_id }
  validates :quantity,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validate :stock_availability, if: :quantity_changed?

  delegate :name, :description, to: :product

  def stock_status
    product.stock < quantity ? Product::STOCK_STATUS_OUT : Product::STOCK_STATUS_AVAILABLE
  end

  def total_price
    product.price * quantity
  end

  private

  def stock_availability
    return unless product && quantity

    errors.add(:quantity, "exceeds available stock.") if quantity > product.stock
  end
end
