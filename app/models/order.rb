class Order < ApplicationRecord
  belongs_to :address, dependent: :destroy
  belongs_to :credit_card, dependent: :destroy

  has_many :order_products, dependent: :destroy

  validates :total_price_cents, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  monetize :total_price_cents,
           with_model_currency: :total_price_currency,
           numericality: { greater_than_or_equal_to: 0 }
end
