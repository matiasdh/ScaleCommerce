class CreditCard < ApplicationRecord
  has_one :order

  validates :last4, presence: true, length: { is: 4 }, numericality: { only_integer: true }
  validates :brand, presence: true
  validates :exp_month, presence: true, inclusion: { in: 1..12 }
  validates :exp_year, presence: true
  validates :token, presence: true
end
