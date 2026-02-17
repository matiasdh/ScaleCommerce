class CreditCard < ApplicationRecord
  has_one :order

  validates :last4, presence: true, length: { is: 4 }, numericality: { only_integer: true }
  validates :brand, presence: true
  validates :exp_month, presence: true, inclusion: { in: 1..12 }
  validates :exp_year, presence: true
  validates :token, presence: true

  def self.build_for_token(token, payment_gateway:)
    gateway_details = payment_gateway.details_for(token)

    new(
      token: gateway_details.token,
      brand: gateway_details.brand,
      last4: gateway_details.last4,
      exp_month: gateway_details.exp_month,
      exp_year: gateway_details.exp_year
    )
  end

  def self.create_from_token!(token, payment_gateway:)
    card = build_for_token(token, payment_gateway:)
    card.save!
    card
  end
end
