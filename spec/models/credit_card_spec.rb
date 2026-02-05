require 'rails_helper'

RSpec.describe CreditCard, type: :model do
  subject { build(:credit_card) }

  describe "Associations" do
    it { should have_one(:order) }
  end

  describe "Validations" do
    it { should validate_presence_of(:brand) }
    it { should validate_presence_of(:token) }

    it { should validate_presence_of(:last4) }
    it { should validate_length_of(:last4).is_equal_to(4) }
    it { should validate_numericality_of(:last4).only_integer }

    it { should validate_presence_of(:exp_month) }
    it { should validate_presence_of(:exp_year) }
    it { should validate_inclusion_of(:exp_month).in_range(1..12) }
  end
end
