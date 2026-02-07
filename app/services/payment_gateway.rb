class PaymentGateway
  # Simulated tokens
  SUCCESS_TOKEN = "tok_success".freeze
  FAIL_TOKEN    = "tok_fail".freeze

  # Common card brands used for simulation
  CARD_BRANDS = [ "Visa", "MasterCard", "Amex" ].freeze

  PaymentResult       = Struct.new(:success, :error_message, :transaction_id, :amount_cents, :currency, keyword_init: true)
  AuthorizationResult = Struct.new(:success, :error_message, :authorization_id, :amount_cents, :currency, keyword_init: true)

  CardDetails = Struct.new(:brand, :last4, :exp_month, :exp_year, :token, keyword_init: true)

  def initialize(latency: 0)
    @latency = latency
  end

  def details_for(token)
    simulate_network_latency

    if token == FAIL_TOKEN
      CardDetails.new(
        brand: CARD_BRANDS.sample,
        last4: "0002",
        exp_month: 12,
        exp_year: 2028,
        token: FAIL_TOKEN
      )
    else
      CardDetails.new(
        brand: CARD_BRANDS.sample,
        last4: "4242",
        exp_month: 12,
        exp_year: 2030,
        token: SUCCESS_TOKEN
      )
    end
  end

  # Authorize a payment (hold funds). Returns an authorization that can be captured later.
  def authorize(token:, amount_cents:, currency: "USD")
    simulate_network_latency

    if token == FAIL_TOKEN
      AuthorizationResult.new(
        success: false,
        error_message: "Insufficient funds",
        authorization_id: nil,
        amount_cents: amount_cents,
        currency: currency
      )
    else
      AuthorizationResult.new(
        success: true,
        error_message: nil,
        authorization_id: "pi_#{SecureRandom.hex(12)}",
        amount_cents: amount_cents,
        currency: currency
      )
    end
  end

  # Capture a previously authorized payment.
  def capture(authorization_id:, amount_cents:, currency: "USD")
    simulate_network_latency

    if authorization_id.blank?
      return PaymentResult.new(
        success: false,
        error_message: "Invalid authorization",
        transaction_id: nil,
        amount_cents: amount_cents,
        currency: currency
      )
    end

    PaymentResult.new(
      success: true,
      error_message: nil,
      transaction_id: "ch_#{SecureRandom.hex(12)}",
      amount_cents: amount_cents,
      currency: currency
    )
  end

  # One-step charge: authorize and capture in a single call.
  # Convenience method for when you don't need to hold funds before capturing.
  def charge(token:, amount_cents:, currency: "USD")
    auth = authorize(token: token, amount_cents: amount_cents, currency: currency)
    return PaymentResult.new(
      success: false,
      error_message: auth.error_message,
      transaction_id: nil,
      amount_cents: amount_cents,
      currency: currency
    ) unless auth.success

    capture(
      authorization_id: auth.authorization_id,
      amount_cents: amount_cents,
      currency: currency
    )
  end

  private

  def simulate_network_latency
    sleep(@latency)
  end
end
