require "rails_helper"

RSpec.describe CheckoutNotificationsChannel, type: :channel do
  let(:shopping_basket_id) { SecureRandom.uuid }

  before { stub_connection }

  describe "#subscribed" do
    context "with valid shopping_basket_id" do
      before { subscribe(shopping_basket_id:) }

      it "subscribes to the stream for the given shopping_basket_id" do
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("checkout_#{shopping_basket_id}")
      end

      it "subscribes to different streams for different basket IDs" do
        other_id = SecureRandom.uuid
        expect(subscription).to have_stream_from("checkout_#{shopping_basket_id}")
        expect(subscription).not_to have_stream_from("checkout_#{other_id}")
      end
    end

    context "when shopping_basket_id is missing" do
      it "rejects subscription" do
        subscribe(shopping_basket_id: nil)

        expect(subscription).to be_rejected
      end
    end
  end

  describe "#unsubscribed" do
    before { subscribe(shopping_basket_id:) }

    it "stops all streams when unsubscribed" do
      unsubscribe

      expect(subscription).not_to have_streams
    end
  end
end
