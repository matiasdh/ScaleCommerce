class PaymentGateway
  # Simulated tokens
  SUCCESS_TOKEN = "tok_success".freeze
  FAIL_TOKEN    = "tok_fail".freeze

  # Common card brands used for simulation
  CARD_BRANDS = [ "Visa", "MasterCard", "Amex" ].freeze

  PaymentResult = Struct.new(:success, :error_message, :transaction_id, :amount_cents, :currency, keyword_init: true)

  CardDetails = Struct.new(:brand, :last4, :exp_month, :exp_year, :token, keyword_init: true)

  def initialize(latency: 1)
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

  def charge(token:, amount_cents:, currency: "USD")
    simulate_network_latency

    if token == FAIL_TOKEN
      PaymentResult.new(
        success: false,
        error_message: "Insufficient funds",
        transaction_id: nil,
        amount_cents: amount_cents,
        currency: currency
      )
    else
      PaymentResult.new(
        success: true,
        error_message: nil,
        transaction_id: "ch_#{SecureRandom.hex(12)}",
        amount_cents: amount_cents,
        currency: currency
      )
    end
  end

  private

  def simulate_network_latency
    sleep(@latency)
  end
end
