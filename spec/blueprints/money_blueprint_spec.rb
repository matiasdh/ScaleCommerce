# spec/blueprints/money_blueprint_spec.rb
require "rails_helper"

RSpec.describe MoneyBlueprint do
  describe ".render_as_hash" do
    subject(:result) { described_class.render_as_hash(money) }
    let(:money)    { Money.new(cents, iso_code) }
    let(:cents)    { 150_00 }

    shared_examples "serializes money" do
      it "serializes cents and currency iso_code" do
        expect(result).to eq(
          cents: cents,
          currency: iso_code
        )
      end
    end

    context "when the currency is USD" do
      let(:iso_code) { "USD" }

      include_examples "serializes money"
    end

    context "when the currency is UYU" do
      let(:iso_code) { "UYU" }

      include_examples "serializes money"
    end
  end
end
