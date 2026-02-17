module ShoppingBaskets
  class CheckoutOrderAtomicService < BaseService
    class EmptyBasketError < StandardError; end
    class PaymentError < StandardError; end

    def initialize(shopping_basket:, email:, payment_token:, address_params:, order:, payment_gateway: PaymentGateway.new)
      @shopping_basket = shopping_basket
      @email = email
      @payment_token = payment_token
      @address_params = address_params
      @payment_gateway = payment_gateway
      @order = order
    end

    def call
      credit_card = CreditCard.build_for_token(payment_token, payment_gateway:)
      auth_result = authorize_payment!(shopping_basket.total_price.cents)

      order = ActiveRecord::Base.transaction do
        credit_card.save!
        address = Address.create!(address_params)
        products_by_id = fetch_products
        purchasable_items = reserve_stock_atomically!
        total_cents = calculate_totals(purchasable_items, products_by_id)
        order = create_or_update_order!(total_cents, credit_card:, address:)
        fulfill_items!(order, purchasable_items, products_by_id)
        cleanup_basket!
        order.authorized!
        order
      end

      capture_payment!(auth_result.authorization_id, order.total_price_cents)
      order.captured!
      order.completed!
      order
    end

    private

    attr_reader :shopping_basket, :email, :payment_token, :address_params, :payment_gateway, :order

    def authorize_payment!(amount_cents)
      raise PaymentError, "Order must be pending or failed to authorize" unless order.pending? || order.failed?

      auth_result = payment_gateway.authorize(
        token: payment_token,
        amount_cents:,
        currency: "USD"
      )
      raise PaymentError, auth_result.error_message unless auth_result.success
      auth_result
    end

    # Assumes shopping_basket loaded with with_associations.
    def fetch_products
      shopping_basket.shopping_basket_products
        .filter_map { |sbp| sbp.product if sbp.product_id }
        .uniq(&:id)
        .index_by(&:id)
    end

    def reserve_stock_batch(basket_items)
      return [] if basket_items.empty?

      sql = build_reserve_stock_sql(basket_items)
      result = Product.connection.exec_query(sql)
      result.map { |row| { product_id: row["product_id"], quantity: row["quantity"] } }
    end

    def build_reserve_stock_sql(basket_items)
      table = Product.quoted_table_name
      placeholders = basket_items.map { "(?, ?)" }.join(", ")
      values = basket_items.flat_map { |i| [ i.product_id, i.quantity ] }

      ApplicationRecord.sanitize_sql_array([
        <<~SQL.squish,
          UPDATE #{table} p
          SET stock = p.stock - items.quantity, updated_at = NOW()
          FROM (VALUES #{placeholders}) AS items(product_id, quantity)
          WHERE p.id = items.product_id AND p.stock >= items.quantity
          RETURNING p.id AS product_id, items.quantity
        SQL
        *values
      ])
    end

    def reserved_by_product_id(reserved)
      reserved.index_by { |r| r[:product_id] }
    end

    def reserve_stock_atomically!
      basket_items = shopping_basket.shopping_basket_products.to_a
      reserved = reserve_stock_batch(basket_items) # Atomic UPDATE returns only products with sufficient stock
      reserved_by_id = reserved_by_product_id(reserved)

      purchasable_items, skipped = basket_items.partition { |item| reserved_by_id.key?(item.product_id) } # Partial fulfillment: split by stock availability
      skipped.each { |item| Rails.logger.info "Skipping item #{item.id} - insufficient stock for Basket #{shopping_basket.id}." }
      raise EmptyBasketError, "No items available in stock." if purchasable_items.empty?

      purchasable_items
    end

    def calculate_totals(purchasable_items, products_by_id)
      purchasable_items.sum { |item| item.quantity * products_by_id[item.product_id].price_cents }
    end

    def capture_payment!(authorization_id, amount_cents)
      capture_result = payment_gateway.capture(
        authorization_id:,
        amount_cents:,
        currency: "USD"
      )

      raise PaymentError, capture_result.error_message unless capture_result.success
    end

    def create_or_update_order!(total_cents, credit_card:, address:)
      order.update!(
        email:,
        address:,
        credit_card:,
        total_price_cents: total_cents,
        total_price_currency: "USD"
      )
      order
    end

    def fulfill_items!(order, items, products_by_id)
      items.each do |basket_item|
        product = products_by_id[basket_item.product_id]

        OrderProduct.create!(
          order:,
          product:,
          quantity: basket_item.quantity,
          unit_price_cents: product.price.cents,
          unit_price_currency: product.price.currency
        )

        basket_item.destroy!
      end
    end

    def cleanup_basket!
      shopping_basket.destroy! if shopping_basket.shopping_basket_products.reload.empty?
    end
  end
end
