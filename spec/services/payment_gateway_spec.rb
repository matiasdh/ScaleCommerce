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

  describe "#charge" do
    let(:amount) { 15_00 }

    context "success scenario" do
      it "returns a successful payment result with a transaction ID" do
        result = subject.charge(token: "tok_success", amount_cents: amount)

        expect(result.success).to be true
        expect(result.transaction_id).to start_with("ch_")
        expect(result.error_message).to be_nil
        expect(result.amount_cents).to eq(amount)
        expect(result.currency).to eq("USD")
      end
    end

    context "failure scenario" do
      it "returns a failed result with the error message" do
        result = subject.charge(token: "tok_fail", amount_cents: amount)

        expect(result.success).to be false
        expect(result.transaction_id).to be_nil
        expect(result.error_message).to eq("Insufficient funds")
        expect(result.amount_cents).to eq(amount)
      end
    end
  end

  describe "Network Simulation" do
    it "sleeps to simulate network latency" do
      slow_gateway = described_class.new(latency: 0.1)

      expect(slow_gateway).to receive(:sleep).with(0.1)

      slow_gateway.charge(token: "tok_success", amount_cents: 100)
    end
  end
end
