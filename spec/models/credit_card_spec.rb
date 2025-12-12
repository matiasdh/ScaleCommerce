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

  describe ".create_from_token!" do
    let(:token) { "tok_success" }

    before do
      allow(PaymentGateway).to receive(:new).and_return(PaymentGateway.new(latency: 0))
    end

    it "fetches details from the gateway and creates a valid card" do
      expect {
        described_class.create_from_token! token
      }.to change(CreditCard, :count).by 1

      card = CreditCard.last

      expect(card.token).to eq(token)
      expect(card.last4).to eq("4242")
      expect(card.exp_year).to eq(2030)
      expect(PaymentGateway::CARD_BRANDS).to include(card.brand)
    end
  end
end
