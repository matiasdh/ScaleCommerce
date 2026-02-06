# API V2 Documentation

Base URL: `/api/v2`

## Overview
API V2 introduces significant performance improvements and architectural changes:
- **Keyset Pagination**: Faster, cursor-based pagination for large datasets.
- **Async Checkout**: Non-blocking checkout process using Background Jobs.
- **Real-time Notifications**: Order status updates via Action Cable.

## Authentication
(Same as V1) - Uses `Shopping-Basket-ID` or `Authorization: Bearer <uuid>`.

## Products

### List Products (Keyset Pagination)
Returns a paginated list of products using a cursor.

- **Endpoint:** `GET /products`
- **Parameters:**
  - `page` (optional, string): The cursor for the next page. If omitted, returns the first page.
  - `limit` (optional, integer): Items per page (default: 20).
- **Example:**
  ```bash
  # Get First Page
  curl "http://localhost:3000/api/v2/products"

  # Get Next Page (using cursor from previous response)
  curl "http://localhost:3000/api/v2/products?page=eyJpZCI6Mj..."
  ```
- **Response:**
  - **Status:** `200 OK`
  - **Body:**
    ```json
    {
      "per_page": 20,
      "next": "eyJpZCI6MjAsIl9vcmRlciI6W1siUmFua...",
      "records": [
        {
          "id": 1,
          "name": "Product Name",
          "price": { "cents": 1000, "currency": "USD" },
          "stock_status": "AVAILABLE"
        }
      ]
    }
    ```
  - **Notes:**
    - `next`: Contains the cursor string for the next page. If `null`, there are no more pages.
    - `record_count` and `pages` (total pages) are **NOT** returned.

## Shopping Basket & Checkout

### Async Checkout
(Documentation pending implementation of `Api::V2::CheckoutsController`)

- **Endpoint:** `POST /shopping_basket/checkout`
- **Status:** `202 Accepted`
- **Body:** Returns `order_uuid` for subscription.
