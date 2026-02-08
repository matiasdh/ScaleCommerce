class Order < ApplicationRecord
  enum :status, {
    pending: "pending",
    authorized: "authorized",
    insufficient_funds: "insufficient_funds",
    captured: "captured",
    partially_fulfilled: "partially_fulfilled",
    fulfilled: "fulfilled",
    completed: "completed",
    failed: "failed"
  }, validate: true

  belongs_to :address, dependent: :destroy, optional: true
  belongs_to :credit_card, dependent: :destroy, optional: true
  belongs_to :shopping_basket, dependent: :destroy, required: false

  has_many :order_products, dependent: :destroy
  has_many :products, through: :order_products

  scope :with_associations, -> {
    includes(order_products: :product)
  }

  validates :shopping_basket_id, uniqueness: { allow_nil: true }

  with_options unless: :pending? do |order|
    order.validates :total_price_cents, presence: true
    order.validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

    order.validates :total_price_cents, presence: true
    order.validates :total_price_cents, numericality: { greater_than: 0 }
  end

  monetize :total_price_cents,
    with_model_currency: :total_price_currency,
    allow_nil: true
end
