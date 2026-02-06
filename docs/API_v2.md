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
