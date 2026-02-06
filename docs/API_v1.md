# API Documentation

Base URL: `/api/v1`

| [Explore V2 Documentation →](API_v2.md) |
| :--- |


## Products

### List Products
Returns a paginated list of products.

- **Endpoint:** `GET /products`
- **Parameters:**
  - `page` (optional, integer): Page number for pagination. Defaults to 1. Fixed page size: 20 items.
- **Example:**
  ```bash
  curl -v "http://localhost:3000/api/v1/products?page=1"
  ```
- **Response:**
  - **Status:** `200 OK`
  - **Body:**
    ```json
    {
      "page": 1,
      "pages": 5,
      "per_page": 20,
      "record_count": 100,
      "records": [
        {
          "id": 1,
          "name": "Product Name",
          "description": "Product Description",
          "price": { "cents": 1000, "currency": "USD" },
          "stock_status": "AVAILABLE"
        }
      ]
    }
    ```
    *   **stock_status**: `AVAILABLE` | `OUT_OF_STOCK`

### Show Product
Returns details of a specific product.

- **Endpoint:** `GET /products/:id`
- **Parameters:**
  - `id` (path, integer): ID of the product.
- **Example:**
  ```bash
  curl -v "http://localhost:3000/api/v1/products/1"
  ```
- **Response:**
  - **Status:** `200 OK`
  - **Body:**
    ```json
    {
      "id": 1,
      "name": "Product Name",
      "description": "Product Description",
      "price": { "cents": 1000, "currency": "USD" },
      "stock_status": "AVAILABLE"
    }
    ```
  - **Status:** `404 Not Found` (if product does not exist)

## Shopping Baskets

All endpoints related to the shopping basket require (or provide) a `Shopping-Basket-ID` header or use the `Authorization` header with a Bearer token to identify the session.

### Show Shopping Basket
Retrieves the current shopping basket. If no valid token is provided, a new empty basket is returned.

**Note:** PROVISIONAL BASKET. If no token is provided, the basket is NOT persisted and NO `Shopping-Basket-ID` token is returned. To get a persistent token, you must add a product.

- **Endpoint:** `GET /shopping_basket`
- **Headers:**
  - `Authorization: Bearer <uuid>` (optional): To retrieve an existing basket.
- **Example:**
  ```bash
  # Create new basket
  curl -v -X GET "http://localhost:3000/api/v1/shopping_basket"

  # Retrieve existing basket
  curl -v -X GET "http://localhost:3000/api/v1/shopping_basket" \
    -H "Authorization: Bearer <your-uuid>"
  ```
- **Response:**
  - **Status:** `200 OK`
  - **Body:**
    ```json
    {
      "total": { "cents": 2000, "currency": "USD" },
      "products": [
        {
          "id": 1,
          "name": "Product Name",
          "description": "Product Description",
          "quantity": 2,
          "stock_status": "AVAILABLE",
          "total": { "cents": 2000, "currency": "USD" }
        }
      ]
    }
    ```
    *   **stock_status**: `AVAILABLE` | `OUT_OF_STOCK`

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
  # 1. Create Basket (No token provided) -> Returns Shopping-Basket-ID header
  curl -v -X POST "http://localhost:3000/api/v1/shopping_basket/products" \
    -H "Content-Type: application/json" \
    -d '{
      "product": {
        "product_id": 1,
        "quantity": 2
      }
    }'

  # 2. Update/Add to Existing Basket (Use token from step 1)
  curl -v -X POST "http://localhost:3000/api/v1/shopping_basket/products" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer <uuid-from-step-1>" \
    -d '{
      "product": {
        "product_id": 1,
        "quantity": 5
      }
    }'
  ```
- **Response:**
  - **Status:** `201 Created`
  - **Body:** Returns the updated Shopping Basket structure (same as GET).

### Checkout
Processes the checkout for the current basket, creating an order.

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
  *   **payment_token**: Use `tok_success` for successful payment simulation or `tok_fail` to simulate a decline.
- **Example:**
  ```bash
  curl -v -X POST "http://localhost:3000/api/v1/shopping_basket/checkout" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer <your-uuid>" \
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
  - **Status:** `201 Created`
  - **Body:**
    ```json
    {
      "id": 1,
      "email": "user@example.com",
      "created_at": "2023-10-27T10:00:00.000Z",
      "total_price": { "cents": 2000, "currency": "USD" },
      "order_products": [
        {
          "id": 1,
          "name": "Product Name",
          "description": "Product Description",
          "quantity": 2,
          "unit_price": { "cents": 1000, "currency": "USD" },
          "total_price": { "cents": 2000, "currency": "USD" }
        }
      ]
    }
    ```
