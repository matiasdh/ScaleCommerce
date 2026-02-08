# ScaleCommerce — High-Scale E-commerce Backend API

[![Ruby](https://img.shields.io/badge/Ruby-3.4-red)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8-red)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-red)](https://redis.io/)
[![Sidekiq](https://img.shields.io/badge/Sidekiq-8-purple)](https://sidekiq.org/)
[![CI](https://img.shields.io/badge/CI-GitHub_Actions-black)](https://github.com/features/actions)

> A production-grade Rails API built to handle high concurrency and strict inventory controls.
> Load-tested, benchmarked, and iteratively improved from V1 to V2.

---

## V1 to V2: Identifying Bottlenecks, Then Solving Them

This project follows an **iterative engineering approach**: V1 was built, load-tested with k6 to find real bottlenecks, and V2 addresses them one by one. Some improvements are already shipped, others are on the roadmap -- each backed by data from the load tests.

### Shipped in V2

| Problem Area | V1 (Baseline) | Bottleneck Found | V2 (Shipped) |
|---|---|---|---|
| **Checkout Flow** | Synchronous (blocks web worker) | Web workers blocked during payment processing, reducing throughput | Async via **Sidekiq** background jobs. Web workers free instantly, traffic spikes absorbed by the queue |
| **Pagination** | Offset-based (`LIMIT/OFFSET` + `COUNT(*)`) | `COUNT(*)` does a full table scan. Offset degrades to O(n) on large datasets | **Keyset pagination**. Index-only access, constant time regardless of dataset size |

### Shipped in V1

| Area | What Was Shipped | Why It Matters |
|---|---|---|
| **Core API** | RESTful endpoints: product catalog with offset pagination, shopping basket, and synchronous checkout with inventory validation | Full e-commerce flow: browse, cart, checkout |
| **Inventory Concurrency** | **Pessimistic locking** (`SELECT ... FOR UPDATE`) with deterministic ID sorting to prevent deadlocks | Prevents race conditions where two users buy the "last" item simultaneously, avoiding overselling |
| **JSON Serialization** | **Blueprinter + Oj** — ~3x faster JSON generation via declarative DSL and optimized C-extension encoder ([benchmarks](https://github.com/okuramasafumi/alba/tree/main/benchmark)) | Jbuilder's template overhead and high memory allocation become bottlenecks at scale |
| **Caching** | **Multi-layer caching**: Redis server-side + HTTP ETags/Last-Modified for conditional GET (304 Not Modified) | 80% of traffic is reads — avoid redundant DB queries on repeated requests |
| **Primary Keys** | **UUID v7** — time-ordered for B-Tree insert performance, opaque to prevent enumeration | Avoids business intelligence leakage from sequential IDs and B-Tree fragmentation from random UUID v4 |
| **Payment Security** | **Tokenized payments** — API receives only payment tokens (`tok_123`). PAN/CVV never touch our infrastructure | Minimizes PCI DSS scope: no card data stored, processed, or transmitted |
| **Business Logic** | **Service Object pattern** with `BaseService` abstraction — controllers stay thin, business rules isolated and testable | Single-responsibility: easy to test, easy to maintain |

### Next on the Roadmap (V3)

| Problem Area | Current Approach | Why It Matters | Planned Improvement |
|---|---|---|---|
| **Inventory Writes** | Pessimistic locking (`SELECT ... FOR UPDATE`) | DB-bound under write concurrency. Requests serialize and queue, causing p95 latency of **9.37s** at 200 users | Atomic SQL updates (`UPDATE ... WHERE stock >= ?`). Eliminates row-level lock contention |
| **Checkout Notifications** | V2 returns `202 Accepted` with no follow-up | Client has no way to know when async checkout completes or fails | Real-time notifications via **ActionCable** (with **AnyCable** for production-grade WebSocket scaling) |
| **User Sessions** | No authentication (anonymous baskets) | No persistent user identity — baskets are ephemeral and can't survive across devices or sessions | **Session-based authentication** with secure, stateful user sessions for persistent baskets and order history |
| **Capacity** | ~150 concurrent users/node | 22% error rate at 1,000 users. Horizontal scaling alone would worsen DB contention | Target **250+ users/node** via atomic updates + read replicas for the 80% read traffic |

> Full analysis: **[Load Testing Report](docs/load_test/load_test_results.md)** | **[V1 API](docs/API_v1.md)** | **[V2 API](docs/API_v2.md)**

---

## Architecture & Design Decisions

### Concurrency Control (The Inventory Problem)

The critical challenge: preventing race conditions when multiple users attempt to purchase the last item simultaneously.

- **Strategy:** Pessimistic Locking (`SELECT ... FOR UPDATE`) -- guarantees correctness above all else.
- **Deadlock Prevention:** Resource IDs are deterministically sorted before locking to prevent deadlocks when users buy overlapping sets of products.
- **Known trade-off:** Load testing confirmed this is the primary bottleneck under write concurrency. The roadmap targets atomic SQL updates (`UPDATE ... WHERE stock >= ?`) to eliminate lock contention.

```ruby
# CheckoutOrderService
Product.transaction do
  # 1. Sort IDs to prevent deadlocks
  # 2. Lock rows for update
  locked_products = Product.where(id: item_ids).order(:id).lock

  # 3. Validate stock and decrement atomically
  # ...
end
```

### Performance Optimizations

- **JSON Serialization:** Replaced Jbuilder with **Blueprinter + Oj** for ~3x faster JSON generation.
- **Multi-layer Caching:** Redis for server-side caching + HTTP ETags/Last-Modified for conditional GET (304 Not Modified).
- **UUID v7 Primary Keys:** Time-ordered UUIDs preserve B-Tree insert performance (unlike random UUID v4) while preventing business intelligence leakage from sequential IDs.

### Security (PCI DSS Compliance)

Credit card numbers are **never stored, processed, or transmitted** by the backend.

- The architecture assumes client-side tokenization directly with the payment provider.
- The API receives only a payment token (e.g., `tok_123`), ensuring PAN and CVV data never touch our infrastructure. This design minimizes PCI DSS scope.

### Service Object Pattern

Business logic is extracted into testable service objects with a `BaseService` abstraction, keeping controllers thin and business rules isolated.

---

## Load Testing & Benchmarks

Rigorous load testing with **k6** against a single node (Puma cluster, 4 workers x 10 threads). Traffic mix: **80% reads / 20% writes** simulating real e-commerce patterns with stateful user journeys and HTTP caching via ETags.

| Metric | 200 VUs | 300 VUs | 600 VUs | 1,000 VUs |
|---|---:|---:|---:|---:|
| **Throughput** | 139 RPS | 197 RPS | 335 RPS | 404 RPS |
| **Error Rate** | 0.00% | 5.67% | 13.94% | 22.93% |
| **p95 Latency** | 9.37s | 4.95s | 3.56s | 3.31s |
| **Checkout Success** | 100% | 94% | 86% | 78% |

**Key insight:** At 200 VUs, zero errors but extreme latency -- requests queue behind database locks instead of failing. As load increases, the queue saturates and requests start timing out, which paradoxically *lowers* reported latency of successful requests.

> Detailed per-run outputs: [1000 VUs](docs/load_test/k6_1000_output.md) | [600 VUs](docs/load_test/k6_600_output.md) | [300 VUs](docs/load_test/k6_300_output.md) | [200 VUs](docs/load_test/k6_200_output.md)

---

## Tech Stack

| Category | Technology |
|---|---|
| **Language** | Ruby 3.4 (YJIT enabled) |
| **Framework** | Ruby on Rails 8 (API-only mode) |
| **Database** | PostgreSQL 16 |
| **Cache** | Redis 7 |
| **Background Jobs** | Sidekiq 8 |
| **Serialization** | Blueprinter + Oj |
| **Pagination** | Pagy (offset + keyset) |
| **Testing** | RSpec, FactoryBot, Faker, Shoulda Matchers |
| **Security** | Brakeman (static analysis), Strong Migrations |
| **CI/CD** | GitHub Actions (RuboCop linting) |
| **Infrastructure** | Docker, Docker Compose, Puma (cluster mode) |

---

## Getting Started

### Prerequisites

- **Ruby 3.4+** (via asdf, rbenv, mise, or system)
- **Docker & Docker Compose** (for PostgreSQL and Redis)
- **just** - `brew install just`
- **direnv** - `brew install direnv` then add hook to your shell:
  ```bash
  # zsh (~/.zshrc)
  eval "$(direnv hook zsh)"

  # bash (~/.bashrc)
  eval "$(direnv hook bash)"

  # fish (~/.config/fish/config.fish)
  direnv hook fish | source
  ```

### Installation

```bash
git clone <repo_url>
cd scale-commerce

bundle install

cp .envrc.sample .envrc

direnv allow
```

### Running Locally

```bash
# View all available commands
just

# Start everything (postgres, redis, rails server)
just start

# Or step by step:
just infra       # Start postgres + redis
just db-setup    # Create, migrate, seed database
just start       # Start Rails server
```

### Running Tests

```bash
# Run all tests
just test

# Run specific file
just test-file spec/requests/api/v2/products_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec
```

### Development Caching

```bash
# Enable/Disable caching in development (required to test Redis caching behavior)
rails dev:cache
```

---

## API Endpoints

### Products

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/products` | List products (offset pagination, 20/page) |
| `GET` | `/api/v2/products` | List products (keyset pagination, 20/page) |
| `GET` | `/api/v1/products/:id` | Product details |

### Basket

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/shopping_basket` | View current basket |
| `POST` | `/api/v1/shopping_basket/products` | Add/update item in basket |

### Checkout

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/shopping_basket/checkout` | Synchronous checkout (V1) |
| `POST` | `/api/v2/shopping_basket/checkout` | Async checkout via Sidekiq (V2) |

> Full documentation: **[V1 API](docs/API_v1.md)** | **[V2 API](docs/API_v2.md)**

---

## Author

**Matias DH**
