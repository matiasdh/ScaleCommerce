class Address < ApplicationRecord
  has_one :order

  validates :line_1, :city, :state, :zip, :country, presence: true
end
