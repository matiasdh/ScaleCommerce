class ShoppingBasket < ApplicationRecord
  after_initialize :set_uuid, if: :new_record?

  validates :uuid, presence: true

  has_one :order, dependent: :nullify

  has_many :shopping_basket_products, dependent: :destroy
  has_many :products, through: :shopping_basket_products

  scope :with_associations, -> {
    includes(shopping_basket_products: :product)
  }

  def total_price
    shopping_basket_products.sum(Money.new(0), &:total_price)
  end

  def products_last_updated_at
    shopping_basket_products.map { |p| p.product.updated_at }.max
  end

  private

  def set_uuid
    self.uuid ||= SecureRandom.uuid_v7
  end
end
