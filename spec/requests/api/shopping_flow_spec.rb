require 'rails_helper'

RSpec.describe "Shopping Flow: Product -> Basket -> Checkout -> Order", type: :request do
  let!(:product_1) { create(:product, price_cents: 30000, stock: 10) }
  let!(:product_2) { create(:product, price_cents: 6000, stock: 5) }

  let(:headers) { {} }

  before do
    allow(PaymentGateway).to receive(:new).and_return(PaymentGateway.new(latency: 0))
  end

  it "complete user flow" do
    # 1. Browse Products
    get "/api/v1/products"
    json = JSON.parse(response.body)
    expect(json).to include(
      "page" => 1,
      "pages" => 1,
      "per_page" => 20,
      "record_count" => 2
    )
    expect(json["records"]).to be_an(Array)
    expect(json["records"].size).to eq(2)

    # 2. Add Item to Basket (First time, no token)
    post "/api/v1/shopping_basket/products",
         params: { product: { product_id: product_1.id, quantity: 1 } }

    expect(response).to have_http_status(:created)

    # Capture the Basket Token
    basket_token = response.headers["Shopping-Basket-ID"]
    expect(basket_token).to be_present

    auth_headers = { "Authorization" => "Bearer #{basket_token}" }

    # 3. Add Another Item (With token)
    post "/api/v1/shopping_basket/products",
         params: { product: { product_id: product_2.id, quantity: 2 } },
         headers: auth_headers

    expect(response).to have_http_status(:created)

    # 4. View Basket
    get "/api/v1/shopping_basket", headers: auth_headers
    expect(response).to have_http_status(:ok)

    basket_json = JSON.parse(response.body)
    expect(basket_json["total_price"]["cents"]).to eq(42000) # (1 * 300_00) + (2 * 60_00) = 300_00 + 120_00 = 420_00
    expect(basket_json["products"].size).to eq(2)

    # 5. Checkout
    checkout_params = {
      payment_token: "tok_success",
      email: "test@example.com",
      address: {
        line_1: "Bulevar Artigas 1180",
        city: "Montevideo",
        state: "Montevideo",
        zip: "11200",
        country: "UY"
      }
    }

    expect {
      post "/api/v1/shopping_basket/checkout",
           params: checkout_params,
           headers: auth_headers
    }.to change(Order, :count).by(1)

    expect(response).to have_http_status(:created)

    order_json = JSON.parse(response.body)
    expect(order_json["total_price"]["cents"]).to eq(420_00)

    # 6. Verify Stock Decrement
    expect(product_1.reload.stock).to eq(9) # 10 - 1
    expect(product_2.reload.stock).to eq(3) # 5 - 2

    # 7. Verify Basket is Empty/Deleted logic
    get "/api/v1/shopping_basket", headers: auth_headers
    expect(response).to have_http_status(:ok)
    final_basket = JSON.parse(response.body)
    expect(final_basket["products"]).to be_empty

    # 8. Verify the created order
    last_order = Order.last

    # Verify order customer and totals
    expect(last_order.email).to eq("test@example.com")
    expect(last_order.total_price_cents).to eq(420_00)

    # Verify order line items are snapshotted (price at purchase time)
    expect(last_order.order_products.count).to eq(2)

    # OrderProduct 1
    switch_item = last_order.order_products.find_by(product: product_1)
    expect(switch_item.quantity).to eq(1)
    expect(switch_item.unit_price_cents).to eq(300_00)

    # OrderProduct 2
    zelda_item = last_order.order_products.find_by(product: product_2)
    expect(zelda_item.quantity).to eq(2)
    expect(zelda_item.unit_price_cents).to eq(60_00)
  end
end
