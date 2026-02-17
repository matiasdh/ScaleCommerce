class CheckoutOrderJob < ApplicationJob
  queue_as :default

  def perform(shopping_basket_id:, email:, payment_token:, address_params:)
    shopping_basket = ShoppingBasket.find(shopping_basket_id)
    stream_name = "checkout_#{shopping_basket.uuid}"

    order = ::ShoppingBaskets::CheckoutOrderService.call(
      shopping_basket: shopping_basket,
      email: email,
      payment_token: payment_token,
      address_params: address_params
    )

    broadcast_completed(stream_name, order)
  rescue ::ShoppingBaskets::CheckoutOrderService::EmptyBasketError => e
    Rails.logger.error("CheckoutOrderJob failed: #{e.message} for basket #{shopping_basket_id}")
    broadcast_failed(stream_name, "empty_basket", e.message)
  rescue ::ShoppingBaskets::CheckoutOrderService::PaymentError => e
    Rails.logger.error("CheckoutOrderJob payment failed: #{e.message} for basket #{shopping_basket_id}")
    broadcast_failed(stream_name, "payment_required", e.message)
  end

  private

  def broadcast_completed(stream_name, order)
    order_with_products = Order.with_associations.find(order.id)
    payload = {
      status: "completed",
      order: OrderBlueprint.render_as_hash(order_with_products)
    }
    ActionCable.server.broadcast(stream_name, payload)
  end

  def broadcast_failed(stream_name, code, message)
    payload = {
      status: "failed",
      error: { code: code, message: message }
    }
    ActionCable.server.broadcast(stream_name, payload)
  end
end
