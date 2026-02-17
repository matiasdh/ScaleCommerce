require "rails_helper"

RSpec.describe CheckoutNotificationsChannel, type: :channel do
  let(:shopping_basket_id) { SecureRandom.uuid }

  before do
    stub_connection
  end

  describe "#subscribed" do
    it "subscribes to the stream for the given shopping_basket_id" do
      subscribe(shopping_basket_id: shopping_basket_id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("checkout_#{shopping_basket_id}")
    end

    it "subscribes to different streams for different basket IDs" do
      other_id = SecureRandom.uuid
      subscribe(shopping_basket_id: shopping_basket_id)

      expect(subscription).to have_stream_from("checkout_#{shopping_basket_id}")
      expect(subscription).not_to have_stream_from("checkout_#{other_id}")
    end
  end

  describe "#unsubscribed" do
    it "stops all streams when unsubscribed" do
      subscribe(shopping_basket_id: shopping_basket_id)
      unsubscribe

      expect(subscription).not_to have_streams
    end
  end
end
