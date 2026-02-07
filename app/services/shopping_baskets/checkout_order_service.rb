module ShoppingBaskets
  class CheckoutOrderService < BaseService
    class EmptyBasketError < StandardError; end
    class PaymentError < StandardError; end

    def initialize(shopping_basket:, email:, payment_token:, address_params:, payment_gateway: PaymentGateway.new)
      @shopping_basket = shopping_basket
      @email = email
      @payment_token = payment_token
      @address_params = address_params
      @payment_gateway = payment_gateway
    end

    def call
      order, auth_result = ActiveRecord::Base.transaction do
        @shopping_basket.lock!

        # 1. Create Address and CreditCard
        @credit_card = CreditCard.create_from_token!(@payment_token, payment_gateway: @payment_gateway)
        @address = Address.create!(@address_params)

        # 2. Authorize the payment (hold funds)
        auth_result = authorize_payment!(@shopping_basket.total_price.cents)

        # 3. Prepare Data
        locked_products_by_id = fetch_locked_products
        purchasable_items, total_cents = calculate_totals(locked_products_by_id)

        # 4. Guard Clause
        raise EmptyBasketError, "No items available in stock." if purchasable_items.empty?

        # 5. Persist Order
        order = create_order!(total_cents)
        fulfill_items!(order, purchasable_items, locked_products_by_id)

        # 6. Cleanup
        cleanup_basket!

        [ order, auth_result ]
      end

      # 7. Capture Payment
      capture_payment!(auth_result.authorization_id, order.total_price_cents)

      order
    end

    private

    def authorize_payment!(amount_cents)
      auth_result = @payment_gateway.authorize(
        token: @payment_token,
        amount_cents: amount_cents,
        currency: "USD"
      )
      raise PaymentError, auth_result.error_message unless auth_result.success
      auth_result
    end

    def fetch_locked_products
      product_ids = @shopping_basket.shopping_basket_products.pluck(:product_id)

      Product.where(id: product_ids)
             .order(:id) # Prevent deadlocks
             .lock       # FOR UPDATE
             .index_by(&:id)
    end

    def calculate_totals(locked_products)
      purchasable_items = []
      total_cents = 0

      @shopping_basket.shopping_basket_products.each do |item|
        product = locked_products[item.product_id]

        if item.quantity <= product.stock
          purchasable_items << item
          total_cents += (item.quantity * product.price_cents)
        else
          Rails.logger.info "Skipping item #{item.id} due to stock for Basket #{@shopping_basket.id}."
        end
      end

      [ purchasable_items, total_cents ]
    end

    def capture_payment!(authorization_id, amount_cents)
      # Capture the authorized payment
      capture_result = @payment_gateway.capture(
        authorization_id: authorization_id,
        amount_cents: amount_cents,
        currency: "USD"
      )

      raise PaymentError, capture_result.error_message unless capture_result.success
    end

    def create_order!(total_cents)
      Order.create!(
        email: @email,
        address: @address,
        credit_card: @credit_card,
        total_price_cents: total_cents,
        total_price_currency: "USD"
      )
    end

    def fulfill_items!(order, items, locked_products)
      items.each do |basket_item|
        product = locked_products[basket_item.product_id]

        # Snapshot
        OrderProduct.create!(
          order: order,
          product: product,
          quantity: basket_item.quantity,
          unit_price_cents: product.price.cents,
          unit_price_currency: product.price.currency
        )

        # Decrement Stock (using the locked instance)
        # Note: 'touch: true' invalidates cache after we implement it
        product.decrement!(:stock, basket_item.quantity, touch: true)

        # Remove from basket
        basket_item.destroy!
      end
    end

    def cleanup_basket!
      # Only destroy if completely empty (Smart Cleanup)
      @shopping_basket.destroy! if @shopping_basket.shopping_basket_products.reload.empty?
    end
  end
end
