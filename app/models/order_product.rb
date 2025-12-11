class OrderProduct < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :product_id,
            uniqueness: { scope: :order_id }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price_cents, presence: true

  monetize :unit_price_cents,
           with_model_currency: :unit_price_currency,
           numericality: { greater_than_or_equal_to: 0 }

  delegate :name, :description, to: :product

  def total_price
    unit_price * quantity
  end
end
