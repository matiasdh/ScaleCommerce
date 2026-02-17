class CheckoutNotificationsChannel < ApplicationCable::Channel
  def subscribed
    return reject unless params[:shopping_basket_id].present?

    stream_from stream_name
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def stream_name
    "checkout_#{params[:shopping_basket_id]}"
  end
end
