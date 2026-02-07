class CheckoutOrderJob < ApplicationJob
  queue_as :default

  def perform(shopping_basket_id:, email:, payment_token:, address_params:)
    shopping_basket = ShoppingBasket.find(shopping_basket_id)

    ::ShoppingBaskets::CheckoutOrderService.call(
      shopping_basket: shopping_basket,
      email: email,
      payment_token: payment_token,
      address_params: address_params
    )
  rescue ::ShoppingBaskets::CheckoutOrderService::EmptyBasketError => e
    Rails.logger.error("CheckoutOrderJob failed: #{e.message} for basket #{shopping_basket_id}")
  rescue ::ShoppingBaskets::CheckoutOrderService::PaymentError => e
    Rails.logger.error("CheckoutOrderJob payment failed: #{e.message} for basket #{shopping_basket_id}")
  end
end
