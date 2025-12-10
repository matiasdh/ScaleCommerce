class Product < ApplicationRecord
  STOCK_STATUS_OUT       = "OUT_OF_STOCK".freeze
  STOCK_STATUS_AVAILABLE = "AVAILABLE".freeze

  validates :name, :currency, presence: true

  validates :stock,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :price_cents,
            presence: true,
            numericality: { only_integer: true }

  monetize :price_cents,
           with_model_currency: :currency,
           numericality: { greater_than: 0 } # price must be > 0

  def stock_status
    stock.zero? ? STOCK_STATUS_OUT : STOCK_STATUS_AVAILABLE
  end
end
