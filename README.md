# ScaleCommerce — High-Scale E-commerce Backend API

[![Ruby](https://img.shields.io/badge/Ruby-3.3-red)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8-red)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-Cache-red)](https://redis.io/)

> A robust, production-grade Rails API designed to handle high concurrency, data integrity, and strict inventory controls.

---

## 📖 Project Overview

**ScaleCommerce** is a high-performance, headless e-commerce API built to demonstrate advanced backend engineering patterns.

The system is designed to robustly handle **5,000+ concurrent users** without sacrificing inventory accuracy. It prioritizes data consistency (ACID) over eventual consistency for the checkout process to prevent overselling, simulating the constraints of a real-world high-volume retail environment.

### Key Features

- **Concurrency Control:** Pessimistic locking strategy with deadlock prevention.
- **Scalable Architecture:** Caching layers (Redis), fast JSON serialization, and background job readiness.
- **Security:** PCI-compliant data handling for payment information.
- **Observability:** Structured logging and request tracing ready.

---

## 🏗️ Architecture & Design Decisions

### 1. Handling Concurrency (The Inventory Problem)

The critical challenge was preventing race conditions when multiple users attempt to purchase the last item of a product simultaneously.

- **Strategy:** Pessimistic Locking (`SELECT ... FOR UPDATE`).
- **Implementation:** During checkout, products are locked at the database level.
- **Deadlock Prevention:** To avoid deadlocks when users buy the same set of items, resource IDs are deterministically ordered before locking.

```ruby
# Service Object: CheckoutOrderService
Product.transaction do
  # 1. Sort IDs to prevent deadlocks
  # 2. Lock rows for update
  locked_products = Product.where(id: item_ids).order(:id).lock

  # 3. Validate stock and decrement atomically
  # ...
end
```

### 2. Performance Optimizations

- **Serialization:** Replaced standard Jbuilder with **Blueprinter + Oj** for ~3x faster JSON generation.
- **Caching:** Redis is used for low-level caching of public product data.
- **Database:** Leveraged PostgreSQL's native `uuid` type combined with **UUID v7**.
  - **Why v7?** Standard UUIDs (v4) cause B-Tree index fragmentation due to randomness. UUID v7 is time-ordered, ensuring sequential inserts and optimal write performance comparable to standard integers.
  - **Why UUIDs?** Prevents business intelligence leakage (competitors guessing order volume via incremental IDs).

### 3. Security (PCI Compliance)

Raw credit card numbers are **never stored or processed** by the backend.

- **Client-Side Tokenization:** The architecture assumes a frontend integration that tokenizes sensitive data directly with the provider.
- **Backend Responsibility:** The API receives only a payment token (e.g., `tok_123`), ensuring that PAN and CVV data never touch our infrastructure, not even in memory. This design significantly reduces the PCI DSS scope.

---

## 📊 Load Testing & Benchmarks (v1)

We conducted rigorous load testing to validate our concurrency handling assertions using **k6** against a single node.

- **Objective:** Support 5,000 concurrent users.
- **Results:**
  - **Bottleneck Identified:** The Architecture is DB-bound under write concurrency due to Pessimistic Locking.
  - **Safe Capacity per Node:** ~150 concurrent users.
  - **At 200 Concurrent Users:** 0% error rate, but high latency (p95 ~9.37s) due to lock contention.
  - **At 1,000 Concurrent Users:** 22% error rate, system saturated at ~400 RPS.
  - **Detailed Report:** See **[docs/load_test/load_test_results.md](docs/load_test/load_test_results.md)** for analysis, comparative tables, and the scaling strategy.

---

## 🛠️ Tech Stack

| Category      | Technology                 |
| ------------- | -------------------------- |
| **Language**  | Ruby 3.3                   |
| **Framework** | Ruby on Rails 8 (API Mode) |
| **Database**  | PostgreSQL 16              |
| **Cache**     | Redis                      |
| **Testing**   | RSpec, FactoryBot, Faker   |

---

## 🚀 Getting Started

### Prerequisites

- **Ruby 3.3+** (managed via [asdf](https://asdf-vm.com/) or rbenv)
- **Docker & Docker Compose** (for PostgreSQL and Redis)

### Installation

```bash
# Clone the repository
git clone <repo_url>
cd scale-commerce

# Install Ruby version (if using asdf)
asdf plugin add ruby
asdf install

# Install dependencies
bundle install
```

### Running Locally

```bash
# 1. Start PostgreSQL & Redis
docker compose up -d

# 2. Setup database (creates, migrates, and seeds)
bundle exec rails db:setup

# 3. Start the server
bundle exec rails server

# 4. Verify it's running
curl http://localhost:3000/api/v1/products
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with coverage report
COVERAGE=true bundle exec rspec
```

### Development Caching

```bash
# Enable/Disable caching in development (Required to test Redis caching behavior)
bundle exec rails dev:cache
```

---

## ⚖️ Trade-offs & Future Roadmap

In the spirit of "Production Mindset," here are the trade-offs made for v1.0 and how they would be addressed in v2.0.

| Feature        | Current Approach (v1.0) | Why?                                                                                         | Future Improvement (v2.0)                                                                                          |
| -------------- | ----------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Inventory**  | Pessimistic Locking     | Guarantees correctness above all else. Easiest to implement correctly for rapid development. | Atomic SQL Updates (`UPDATE ... WHERE stock >= ?`). Reduces lock contention significantly.                         |
| **Checkout**   | Synchronous             | Simple error handling for the client.                                                        | Asynchronous (Background Jobs). Move payment processing to Sidekiq/SolidQueue to handle traffic spikes gracefully. |
| **Pagination** | Page-based              | Standard Rails default. Executes `SELECT COUNT(*)` to support total page numbers in UI.      | Cursor-based pagination. Avoids counting full tables, essential for scaling to millions of rows.                   |

---

## 📚 API Documentation

See **[docs/API_v1.md](docs/API_v1.md)** for legacy V1 endpoints.
See **[docs/API_v2.md](docs/API_v2.md)** for the new V2 API (Keyset Pagination, Async Checkout).

### Products

| Method | Endpoint               | Description                                      |
| ------ | ---------------------- | ------------------------------------------------ |
| `GET`  | `/api/v1/products`     | List all available products. Supports `page` (Fixed 20/page). |
| `GET`  | `/api/v1/products/:id` | Get details for a single product.                |

### Basket

| Method | Endpoint | Description |
| ------ | -------- | ----------- |
| `GET` | `/api/v1/shopping_basket` | View current shopping basket. |
| `POST` | `/api/v1/shopping_basket/products` | Add item to shopping basket. |

### Checkout

| Method | Endpoint | Description |
| ------ | -------- | ----------- |
| `POST` | `/api/v1/shopping_basket/checkout` | Finalize order. Requires `email`, `address`, and `payment_token`. |

---

## 👤 Author

**Matías DH**
