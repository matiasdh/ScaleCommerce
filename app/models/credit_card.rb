class CreditCard < ApplicationRecord
  has_one :order

  validates :last4, presence: true, length: { is: 4 }, numericality: { only_integer: true }
  validates :brand, presence: true
  validates :exp_month, presence: true, inclusion: { in: 1..12 }
  validates :exp_year, presence: true
  validates :token, presence: true

  def self.create_from_token!(token)
    gateway_details = PaymentGateway.new.details_for(token)

    create!(
      token: gateway_details.token,
      brand: gateway_details.brand,
      last4: gateway_details.last4,
      exp_month: gateway_details.exp_month,
      exp_year: gateway_details.exp_year
    )
  end
end
