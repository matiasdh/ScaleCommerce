# API V2 Documentation

Base URL: `/api/v2`

| [Back to V1 Documentation ←](API_v1.md) |
| :--- |

## Overview

API V2 introduces **Keyset Pagination** for improved performance on large datasets.

## What is Keyset Pagination (Page Numbers)?

Keyset pagination (also called cursor-based pagination) is a more efficient alternative to offset-based pagination (`LIMIT/OFFSET`). This implementation uses **page numbers** instead of opaque cursor strings for simpler debugging and familiar UX.

### V1 vs V2 Comparison

| Feature | V1 (Offset) | V2 (Keyset) |
|---------|-------------|-------------|
| Query | `SELECT * FROM products LIMIT 20 OFFSET 40` + `COUNT(*)` | `SELECT * FROM products WHERE id > 20 LIMIT 20` |
| Performance | Degrades on large datasets | Constant, uses index |
| Total count | Yes (`record_count`, `pages`) | No |
| Navigation | Jump to any page | Next/Previous only |

**Key Benefits:**
- No expensive `COUNT(*)` queries
- Uses database indexes efficiently
- Consistent performance regardless of dataset size

---

## Products

### List Products (Keyset Pagination)
Returns a paginated list of products.

- **Endpoint:** `GET /products`
- **Parameters:**
  - `page` (optional, integer): Page number. Defaults to 1.
- **Example:**
  ```bash
  # Get first page
  curl "http://localhost:3000/api/v2/products"

  # Get page 2
  curl "http://localhost:3000/api/v2/products?page=2"
  ```
- **Response:**
  - **Status:** `200 OK`
  - **Body:**
    ```json
    {
      "next": 2,
      "previous": null,
      "per_page": 20,
      "records": [
        {
          "id": 1,
          "name": "Mediocre Rubber Clock",
          "description": "Product description here",
          "price": { "cents": 15100, "currency": "USD" },
          "stock_status": "AVAILABLE"
        }
      ]
    }
    ```
  - **Fields:**
    - `next`: Next page number (null if last page)
    - `previous`: Previous page number (null if first page)
    - `per_page`: Items per page (fixed at 20)
    - **Note:** Does NOT include `record_count` or `pages` (total pages)

### Show Product
Returns details of a specific product.

- **Endpoint:** `GET /products/:id`
- **Parameters:**
  - `id` (path, integer): ID of the product.
- **Example:**
  ```bash
  curl "http://localhost:3000/api/v2/products/1"
  ```
- **Response:**
  - **Status:** `200 OK`
  - **Body:**
    ```json
    {
      "id": 1,
      "name": "Mediocre Rubber Clock",
      "description": "Product description here",
      "price": { "cents": 15100, "currency": "USD" },
      "stock_status": "AVAILABLE"
    }
    ```
  - **Status:** `404 Not Found` (if product does not exist)

---

## Shopping Baskets

All endpoints related to the shopping basket require (or provide) a `Shopping-Basket-ID` header or use the `Authorization` header with a Bearer token to identify the session. Same behavior as V1 — basket endpoints are available in V2 for a complete flow.

### Show Shopping Basket
Retrieves the current shopping basket. If no valid token is provided, a new empty basket is returned.

**Note:** PROVISIONAL BASKET. If no token is provided, the basket is NOT persisted and NO `Shopping-Basket-ID` token is returned. To get a persistent token, you must add a product.

- **Endpoint:** `GET /shopping_basket`
- **Headers:**
  - `Authorization: Bearer <uuid>` (optional): To retrieve an existing basket.
- **Example:**
  ```bash
  # Empty basket (no token)
  curl "http://localhost:3000/api/v2/shopping_basket"

  # Retrieve existing basket
  curl "http://localhost:3000/api/v2/shopping_basket" \
    -H "Authorization: Bearer <your-uuid>"
  ```
- **Response:**
  - **Status:** `200 OK`
  - **Body:**
    ```json
    {
      "products": [],
      "total_price": { "cents": 0, "currency": "USD" }
    }
    ```
    With items:
    ```json
    {
      "products": [
        {
          "id": 1,
          "name": "Mediocre Rubber Clock 0",
          "description": "Product description here",
          "quantity": 2,
          "stock_status": "AVAILABLE",
          "total_price": { "cents": 30200, "currency": "USD" }
        }
      ],
      "total_price": { "cents": 30200, "currency": "USD" }
    }
    ```
  - **Fields:**
    - `stock_status`: `AVAILABLE` | `OUT_OF_STOCK`

### Add/Update Product in Basket
Adds a product to the basket or updates its quantity.

**Note:** If no token is provided, this endpoint creates a new persisted basket and returns the `Shopping-Basket-ID` header. Save this token for subsequent requests.

- **Endpoint:** `POST /shopping_basket/products`
- **Headers:**
  - `Authorization: Bearer <uuid>` (optional: required to update an existing basket)
- **Parameters (JSON Body):**
  ```json
  {
    "product": {
      "product_id": 1,
      "quantity": 2
    }
  }
  ```
- **Example:**
  ```bash
  # 1. Create basket (no token) — returns Shopping-Basket-ID header
  curl -v -X POST "http://localhost:3000/api/v2/shopping_basket/products" \
    -H "Content-Type: application/json" \
    -d '{"product": {"product_id": 1, "quantity": 2}}'

  # 2. Update existing basket (use token from step 1)
  curl -v -X POST "http://localhost:3000/api/v2/shopping_basket/products" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer <uuid-from-step-1>" \
    -d '{"product": {"product_id": 1, "quantity": 5}}'
  ```
- **Response:**
  - **Status:** `201 Created`
  - **Headers:** `Shopping-Basket-ID: <uuid>` (when creating new basket)
  - **Body:** Returns the updated shopping basket structure (same as GET).

---

## Checkout (Async)

Processes the checkout asynchronously. Returns immediately with `202 Accepted` and provides WebSocket subscription details to receive completion notifications.

**Prerequisites:** Create a basket and add products via V2 (`POST /api/v2/shopping_basket/products`). Use the `Shopping-Basket-ID` header from the response or the basket UUID for the `Authorization` header.

- **Endpoint:** `POST /shopping_basket/checkout`
- **Headers:**
  - `Authorization: Bearer <uuid>` (required)
- **Parameters (JSON Body):**
  ```json
  {
    "payment_token": "tok_success",
    "email": "user@example.com",
    "address": {
      "line_1": "123 Main St",
      "line_2": "Apt 4B",
      "city": "New York",
      "state": "NY",
      "zip": "10001",
      "country": "US"
    }
  }
  ```
  - `payment_token`: Use `tok_success` for successful payment simulation or `tok_fail` to simulate a decline.
- **Example:**
  ```bash
  # 1. Create basket and add product (V2) — save Shopping-Basket-ID from response headers
  curl -v -X POST "http://localhost:3000/api/v2/shopping_basket/products" \
    -H "Content-Type: application/json" \
    -d '{"product": {"product_id": 1, "quantity": 2}}'

  # 2. Checkout — use basket UUID from step 1
  curl -v -X POST "http://localhost:3000/api/v2/shopping_basket/checkout" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer <uuid-from-step-1>" \
    -d '{
      "payment_token": "tok_success",
      "email": "user@example.com",
      "address": {
        "line_1": "123 Main St",
        "line_2": "Apt 4B",
        "city": "New York",
        "state": "NY",
        "zip": "10001",
        "country": "US"
      }
    }'
  ```
- **Response:**
  - **Status:** `202 Accepted`
  - **Body:**
    ```json
    {
      "message": "Checkout processing started",
      "notifications": {
        "channel": "CheckoutNotificationsChannel",
        "params": {
          "shopping_basket_id": "019c68f2-80b8-7179-b9c5-805060290f97"
        }
      }
    }
    ```
  - **Fields:**
    - `message`: Confirmation that checkout was queued
    - `notifications`: Use this to subscribe to real-time updates via WebSocket

### Checkout Notifications (WebSocket)

Subscribe to receive checkout completion or failure in real time.

- **WebSocket endpoint:** `ws://localhost:3000/cable` (replace host for other environments)
- **Subscription:** Use the `notifications` object from the 202 response:

  ```javascript
  const { channel, params } = response.notifications;
  consumer.subscriptions.create(
    { channel, ...params },
    { received: (data) => handleCheckoutResult(data) }
  );
  ```

  Example: `{ channel: "CheckoutNotificationsChannel", shopping_basket_id: "01936e2a-..." }`

- **Message formats:**

  **Success (status: completed):**
  ```json
  {
    "status": "completed",
    "order": {
      "id": "01936e2a-...",
      "email": "user@example.com",
      "total_price": { "cents": 2000, "currency": "USD" },
      "order_products": [...]
    }
  }
  ```
  The `order` object matches V1 checkout response format.

  **Failure (status: failed):**
  ```json
  {
    "status": "failed",
    "error": {
      "code": "empty_basket",
      "message": "No items available in stock."
    }
  }
  ```
  Error codes: `empty_basket`, `payment_required`
