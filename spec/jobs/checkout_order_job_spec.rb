require 'rails_helper'

RSpec.describe CheckoutOrderJob, type: :job do
  include ActiveJob::TestHelper

  let(:basket) { create(:shopping_basket) }
  let(:product) { create(:product, stock: 10, price_cents: 10_00) }
  let(:email) { "test@example.com" }
  let(:payment_token) { "tok_success" }
  let(:address_params) do
    {
      "line_1" => "123 Calle Falsa",
      "line_2" => "Apt 4",
      "city" => "Montevideo",
      "state" => "Montevideo",
      "zip" => "11300",
      "country" => "UY"
    }
  end

  before do
    create(:shopping_basket_product, shopping_basket: basket, product: product, quantity: 2)
  end

  describe "queue configuration" do
    it "is queued to the default queue" do
      expect(described_class.queue_name).to eq("default")
    end
  end

  describe "job enqueueing" do
    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = original_adapter
    end

    it "can be enqueued with perform_later" do
      expect {
        described_class.perform_later(
          shopping_basket_id: basket.id,
          email: email,
          payment_token: payment_token,
          address_params: address_params
        )
      }.to have_enqueued_job(CheckoutOrderJob)
    end

    it "enqueues with correct arguments" do
      expect {
        described_class.perform_later(
          shopping_basket_id: basket.id,
          email: email,
          payment_token: payment_token,
          address_params: address_params
        )
      }.to have_enqueued_job(CheckoutOrderJob).with(
        shopping_basket_id: basket.id,
        email: email,
        payment_token: payment_token,
        address_params: address_params
      )
    end
  end

  describe "#perform" do
    context "with valid parameters" do
      it "calls CheckoutOrderService with correct parameters" do
        expect(ShoppingBaskets::CheckoutOrderService).to receive(:call).with(
          shopping_basket: basket,
          email: email,
          payment_token: payment_token,
          address_params: address_params
        ).and_call_original

        described_class.perform_now(
          shopping_basket_id: basket.id,
          email: email,
          payment_token: payment_token,
          address_params: address_params
        )
      end

      it "creates an order when service succeeds" do
        expect {
          described_class.perform_now(
            shopping_basket_id: basket.id,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        }.to change(Order, :count).by(1)
      end

      it "broadcasts completed status with order when service succeeds" do
        expect {
          described_class.perform_now(
            shopping_basket_id: basket.id,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        }.to have_broadcasted_to("checkout_#{basket.uuid}").with(
          hash_including(status: "completed", order: hash_including("id", "email", "total_price", "order_products"))
        )
      end
    end

    context "when shopping basket does not exist" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          described_class.perform_now(
            shopping_basket_id: 99999,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "does not call CheckoutOrderService when basket is not found" do
        expect(ShoppingBaskets::CheckoutOrderService).not_to receive(:call)

        expect {
          described_class.perform_now(
            shopping_basket_id: 99999,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when checkout fails with EmptyBasketError" do
      before do
        allow(ShoppingBaskets::CheckoutOrderService).to receive(:call)
          .and_raise(ShoppingBaskets::CheckoutOrderService::EmptyBasketError.new("Basket is empty"))
      end

      it "logs the error and does not re-raise" do
        allow(Rails.logger).to receive(:error)
        expect {
          described_class.perform_now(
            shopping_basket_id: basket.id,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/CheckoutOrderJob failed: Basket is empty/)
      end

      it "broadcasts failed status with error" do
        expect {
          described_class.perform_now(
            shopping_basket_id: basket.id,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        }.to have_broadcasted_to("checkout_#{basket.uuid}").with(
          status: "failed",
          error: { code: "empty_basket", message: "Basket is empty" }
        )
      end
    end

    context "when checkout fails with PaymentError" do
      before do
        allow(ShoppingBaskets::CheckoutOrderService).to receive(:call)
          .and_raise(ShoppingBaskets::CheckoutOrderService::PaymentError.new("Insufficient funds"))
      end

      it "logs the error and does not re-raise" do
        allow(Rails.logger).to receive(:error)
        expect {
          described_class.perform_now(
            shopping_basket_id: basket.id,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/CheckoutOrderJob payment failed: Insufficient funds/)
      end

      it "broadcasts failed status with error" do
        expect {
          described_class.perform_now(
            shopping_basket_id: basket.id,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        }.to have_broadcasted_to("checkout_#{basket.uuid}").with(
          status: "failed",
          error: { code: "payment_required", message: "Insufficient funds" }
        )
      end
    end

    context "when service raises an unexpected error" do
      before do
        allow(ShoppingBaskets::CheckoutOrderService).to receive(:call)
          .and_raise(StandardError.new("Unexpected error"))
      end

      it "does not catch unexpected errors" do
        expect {
          described_class.perform_now(
            shopping_basket_id: basket.id,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        }.to raise_error(StandardError, "Unexpected error")
      end

      it "does not log unexpected errors with job-specific messages" do
        allow(Rails.logger).to receive(:error)
        begin
          described_class.perform_now(
            shopping_basket_id: basket.id,
            email: email,
            payment_token: payment_token,
            address_params: address_params
          )
        rescue StandardError
        end
        expect(Rails.logger).not_to have_received(:error).with(/CheckoutOrderJob/)
      end
    end
  end
end
