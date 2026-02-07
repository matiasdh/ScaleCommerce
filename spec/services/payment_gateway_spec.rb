require 'rails_helper'

RSpec.describe PaymentGateway do
  subject { described_class.new(latency: 0) }

  describe "#details_for" do
    context "with a success token" do
      let(:result) { subject.details_for("tok_success") }

      it "returns valid card details with a random brand" do
        expect(result).to be_a(PaymentGateway::CardDetails)

        expect(PaymentGateway::CARD_BRANDS).to include(result.brand)

        expect(result.last4).to eq("4242")
        expect(result.exp_year).to eq(2030)

        expect(result.token).to eq(PaymentGateway::SUCCESS_TOKEN)
      end
    end

    context "with the fail token" do
      let(:result) { subject.details_for("tok_fail") }

      it "returns card details specific to the failure scenario" do
        expect(result).to be_a(PaymentGateway::CardDetails)

        # La marca sigue siendo random
        expect(PaymentGateway::CARD_BRANDS).to include(result.brand)

        # Datos fijos del escenario de fallo
        expect(result.last4).to eq("0002")
        expect(result.exp_year).to eq(2028)
        expect(result.token).to eq(PaymentGateway::FAIL_TOKEN)
      end
    end
  end

  describe "#authorize" do
    let(:amount) { 15_00 }

    context "success scenario" do
      it "returns a successful authorization with a payment intent ID" do
        result = subject.authorize(token: "tok_success", amount_cents: amount)

        expect(result).to be_a(PaymentGateway::AuthorizationResult)
        expect(result.success).to be true
        expect(result.authorization_id).to start_with("pi_")
        expect(result.error_message).to be_nil
        expect(result.amount_cents).to eq(amount)
        expect(result.currency).to eq("USD")
      end
    end

    context "failure scenario" do
      it "returns a failed authorization with the error message" do
        result = subject.authorize(token: "tok_fail", amount_cents: amount)

        expect(result.success).to be false
        expect(result.authorization_id).to be_nil
        expect(result.error_message).to eq("Insufficient funds")
        expect(result.amount_cents).to eq(amount)
      end
    end
  end

  describe "#capture" do
    let(:amount) { 15_00 }
    let(:authorization_id) { "pi_#{SecureRandom.hex(12)}" }

    context "with a valid authorization_id" do
      it "returns a successful payment result with a charge ID" do
        result = subject.capture(
          authorization_id: authorization_id,
          amount_cents: amount,
          currency: "USD"
        )

        expect(result.success).to be true
        expect(result.transaction_id).to start_with("ch_")
        expect(result.error_message).to be_nil
        expect(result.amount_cents).to eq(amount)
        expect(result.currency).to eq("USD")
      end
    end

    context "with a blank authorization_id" do
      it "returns a failed result" do
        result = subject.capture(
          authorization_id: "",
          amount_cents: amount,
          currency: "USD"
        )

        expect(result.success).to be false
        expect(result.transaction_id).to be_nil
        expect(result.error_message).to eq("Invalid authorization")
      end
    end
  end
end
