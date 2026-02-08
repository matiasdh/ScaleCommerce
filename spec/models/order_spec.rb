require 'rails_helper'

RSpec.describe Order, type: :model do
  subject { build(:order) }

  describe "Associations" do
    it { should belong_to(:address).dependent(:destroy).optional }
    it { should belong_to(:credit_card).dependent(:destroy).optional }
    it { should belong_to(:shopping_basket).dependent(:destroy).optional }
    it { should have_many(:order_products).dependent(:destroy) }
  end

  describe 'scope .with_associations' do
    let!(:order) { create(:order, :with_products) }

    it 'eager loads order_products and their nested products' do
      record = described_class.with_associations.find(order.id)

      expect(record.association(:order_products)).to be_loaded
      record.order_products.each do |order_product|
        expect(order_product.association(:product)).to be_loaded
      end
    end
  end

  describe "Validations" do
    context "when status is pending" do
      subject { build(:order, status: :pending) }

      it "allows total_price_cents to be nil" do
        subject.total_price_cents = nil
        expect(subject).to be_valid
      end

      it "allows total_price_cents to be 0" do
        subject.total_price_cents = 0
        expect(subject).to be_valid
      end

      it "allows email to be nil" do
        subject.email = nil
        expect(subject).to be_valid
      end

      it "allows address_id to be nil" do
        subject.address_id = nil
        expect(subject).to be_valid
      end

      it "allows credit_card_id to be nil" do
        subject.credit_card_id = nil
        expect(subject).to be_valid
      end

      it "can be created with all optional fields as nil" do
        order = build(:order,
          status: :pending,
          total_price_cents: nil,
          email: nil,
          address: nil,
          credit_card: nil
        )
        expect(order).to be_valid
        expect(order.save).to be true
      end
    end

    context "when status is not pending" do
      subject { build(:order, status: :authorized) }

      it { should validate_presence_of(:total_price_cents) }
      it { should validate_presence_of(:email) }

      it "validates total_price_cents is greater than 0" do
        subject.total_price_cents = 0
        expect(subject).not_to be_valid
        expect(subject.errors[:total_price_cents]).to be_present
      end

      it "validates email format" do
        subject.email = "invalid_email"
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to be_present
      end
    end

    context "shopping_basket_id uniqueness" do
      let!(:shopping_basket) { create(:shopping_basket) }
      subject { build(:order, shopping_basket: shopping_basket, status: :authorized) }

      it { should validate_uniqueness_of(:shopping_basket_id).allow_nil }
    end

    context "email format" do
      subject { build(:order, status: :authorized) }

      it { should allow_value("user@example.com").for(:email) }
      it { should allow_value("name+tag@mail.co.uk").for(:email) }

      it { should_not allow_value("user").for(:email) }
      it { should_not allow_value("").for(:email) }
    end
  end

  describe "Status enum" do
    it "has the correct enum values" do
      expect(described_class.statuses.keys).to match_array([
        "pending",
        "authorized",
        "insufficient_funds",
        "captured",
        "partially_fulfilled",
        "fulfilled",
        "completed",
        "failed"
      ])
    end

    it "defaults to pending status" do
      order = build(:order)
      expect(order.status).to eq("pending")
    end

    it "allows setting valid status values" do
      order = build(:order)

      described_class.statuses.keys.each do |status|
        order.status = status
        # When status is pending, order can be valid without required fields
        # When status is not pending, order needs required fields
        if status == "pending"
          order.total_price_cents = nil
          order.email = nil
        else
          order.total_price_cents ||= 1000
          order.email ||= "test@example.com"
        end
        expect(order).to be_valid
      end
    end

    it "does not allow invalid status values" do
      order = build(:order)
      order.status = "invalid_status"

      expect(order).not_to be_valid
      expect(order.errors[:status]).to include("is not included in the list")
    end

    it "provides status predicate methods" do
      order = build(:order, status: :pending)
      expect(order.pending?).to be true
      expect(order.authorized?).to be false

      order.status = :authorized
      expect(order.authorized?).to be true
      expect(order.pending?).to be false
    end
  end

  describe "Monetize" do
    it { is_expected.to monetize(:total_price).with_model_currency(:total_price_currency) }

    context "when status is not pending" do
      subject { build(:order, status: :authorized) }

      it "validates total_price_cents is greater than 0" do
        subject.total_price_cents = 0
        expect(subject).not_to be_valid
        expect(subject.errors[:total_price_cents]).to be_present
      end
    end
  end
end
