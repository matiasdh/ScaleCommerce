module ShoppingBaskets
  class CheckoutOrderService < BaseService
    class EmptyBasketError < StandardError; end
    class PaymentError < StandardError; end

    def initialize(shopping_basket:, email:, credit_card:, address:)
      @shopping_basket = shopping_basket
      @email = email
      @credit_card = credit_card
      @address = address
      @payment_gateway = PaymentGateway.new
    end

    def call
      ActiveRecord::Base.transaction do
        @shopping_basket.lock!

        # 1. Prepare Data
        locked_products_by_id = fetch_locked_products
        purchasable_items, total_cents = calculate_totals(locked_products_by_id)

        # 2. Guard Clause
        raise EmptyBasketError, "Basket is empty or all items are out of stock." if purchasable_items.empty?

        # 3. Process Payment
        process_payment!(total_cents)

        # 4. Persist Order
        order = create_order!(total_cents)
        fulfill_items!(order, purchasable_items, locked_products_by_id)

        # 5. Cleanup
        cleanup_basket!

        order
      end
    end

    private

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

    def process_payment!(amount_cents)
      result = @payment_gateway.charge(
        token: @credit_card.token,
        amount_cents: amount_cents,
        currency: "USD"
      )

      raise PaymentError, result.error_message unless result.success
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
