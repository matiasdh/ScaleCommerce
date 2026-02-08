class Order < ApplicationRecord
  belongs_to :address, dependent: :destroy
  belongs_to :credit_card, dependent: :destroy
  belongs_to :shopping_basket, dependent: :destroy, required: false

  has_many :order_products, dependent: :destroy
  has_many :products, through: :order_products

  scope :with_associations, -> {
    includes(order_products: :product)
  }

  validates :total_price_cents, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :shopping_basket_id, presence: true, uniqueness: true

  monetize :total_price_cents,
           with_model_currency: :total_price_currency,
           numericality: { greater_than_or_equal_to: 0 }
end
