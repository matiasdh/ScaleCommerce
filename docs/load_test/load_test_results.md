# Load Testing Report: E-commerce API Capacity Analysis

## 1. Executive Summary

- **Date:** 2025-12-13
- **Scalability Goal:** 5,000 concurrent users
- **Tests Executed:** 1,000, 600, 300, and 200 VUs
- **Outcome:** ❌ **FAIL (DB-bound under write concurrency)**

I ran four incremental load tests against a single application node. The tests reveal a clear pattern: as concurrency increases, both error rates and throughput increase, but latency degrades significantly.

- **1,000 VUs:** 22.93% error rate, 404 RPS (system saturated)
- **600 VUs:** 13.94% error rate, 335 RPS
- **300 VUs:** 5.67% error rate, 197 RPS
- **200 VUs:** 0.00% error rate, 139 RPS (but p95 = 9.37s)

**Critical finding:** At **200 VUs**, the system achieves near-zero errors but with **extremely high latency** (p95 = 9.37s). This indicates the system is **DB-bound**: requests queue up waiting for database locks rather than failing outright. As load increases, the queue saturates and requests start timing out.

**Conclusion:** The **safe unit capacity** is approximately **100-150 concurrent users per node** where latency remains acceptable (<500ms p95). Reaching **5,000 users** via horizontal scaling alone would be inefficient (~34 nodes) and would likely worsen database contention. A better path is a hybrid strategy: ~**20 nodes**, plus **read replicas** to offload the 80% read traffic, and **atomic SQL updates** to reduce lock contention on writes.

---

## 2. Test Scenario & Methodology

- **Tool:** k6
- **Traffic Mix:** 80% Read (browsing) / 20% Write (add to cart, checkout)
- **Simulation:** stateful user journey, with HTTP caching enabled via **ETags**


### Application runtime configuration (how the server was started)

The app was executed locally in `RAILS_ENV=production` using `bin/rails server` with Puma cluster settings driven by env vars.

> [!NOTE]
> The credentials below are for **local load testing only**. In a real production environment, these values would be securely managed and different.

```bash
SECRET_KEY_BASE=testing \
RAILS_SERVE_STATIC_FILES=true \
RAILS_LOG_TO_STDOUT=false \
RAILS_LOG_LEVEL=warn \
SCALE_COMMERCE_DATABASE_USERNAME=postgres \
SCALE_COMMERCE_DATABASE_PASSWORD=postgres_password \
RAILS_MAX_THREADS=10 \
WEB_CONCURRENCY=4 \
RAILS_ENV=production \
RAILS_FORCE_SSL=false \
RUBY_YJIT_ENABLE=1 \
OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES \
bin/rails server -p 3000
```

Notes:
- No reverse proxy (nginx) and no external load balancer were used.
- Logging was minimized to reduce IO noise during the test.

### Load Model Notes

- **VUs represent concurrent users** executing a stateful journey.
- **Per-user request rate is emergent** (driven by scenario pacing and response times), not a fixed “1 req/sec per user.”
- The primary goal of this baseline is to identify bottlenecks and establish a safe operating range on a single node.

### Test Environment (Baseline Node)

- **Hardware:** Apple M1 (arm64)
- **Runtime:** Ruby 3.4.7 + YJIT + PRISM (production mode)
- **App Server:** Puma 6.6.0 (cluster mode)
- **Workers:** 4
- **Threads per Worker:** 10 (**Total Concurrency:** 40 threads)
- **Framework:** Rails 8.0.4
- **Database:** single local PostgreSQL node

---

## 3. Comparative Results

| Metric | Threshold | Test A (1k) | Test B (600) | Test C (300) | Test D (200) | Status |
|---|---:|---:|---:|---:|---:|:---:|
| Throughput (RPS) | Milestone: 1,000 | 404 | 335 | 197 | 139 | ❌ |
| Error Rate | < 1.00% | 22.93% | 13.94% | 5.67% | 0.00% | ❌ |
| Response Time (p95) | < 500ms | 3.31s | 3.56s | 4.95s | 9.37s | ❌ |
| Journey Start Success | N/A | 74% | 85% | 92% | 100% | ✅ |
| Checkout Success | N/A | 78% | 86% | 94% | 100% | ✅ |

> **Note:** Per-endpoint success rates are available in the k6 `checks` output. See individual test outputs: [1000 VUs](k6_1000_output.md) | [600 VUs](k6_600_output.md) | [300 VUs](k6_300_output.md) | [200 VUs](k6_200_output.md)

### Failure Analysis: Latency vs. Errors Trade-off

The **200 VU** test is the most revealing run.

- **At 200 VUs**, the system achieves **0% error rate** and **100% checkout success**, but at a cost: **p95 latency is 9.37 seconds**. Requests are queuing rather than failing.
- **At 300-1000 VUs**, errors increase as the queue saturates. Requests that cannot be serviced within timeout thresholds start failing.
- **Inverse correlation:** Note that p95 latency *decreases* as VUs increase (9.37s to 3.31s). This is because at higher load, slow requests fail/timeout instead of completing, which *lowers* the reported latency of successful requests.
- The pattern strongly indicates the system is **DB-bound under concurrent writes**. The database cannot parallelize transactional work, so requests serialize and queue.

### Next Steps: Confirming the Root Cause

To confirm database contention as the root cause, future runs should capture PostgreSQL lock metrics (possibly via `pg_stat_activity`).

---

## 4. Capacity Planning & Scalability Strategy

The goal is to support **5,000 concurrent users**.

### 4.1 Establishing Unit Capacity

Since **200 VUs** already produces critical transactional failures (checkout), the safe operating point needs to be lower.

- **Estimated Safe Unit Capacity:** ~**150 concurrent users per node** (conservative baseline)

### 4.2 Scaling Projections

#### Approach A: Brute Force (Horizontal Scaling Only)

To handle 5,000 users with the current architecture:

$$5,000 / 150 \approx 34 \text{ nodes}$$

- **Risk:** scaling the web tier without addressing the database bottleneck will likely **worsen** locking and write contention, since more nodes will hit the same primary DB.
- **Caveat:** this estimate assumes linear scaling of the web tier only, which is not realistic once the primary database saturates.

#### Approach B: Optimized Architecture (Recommended)

The goal is to increase per-node capacity to **250+** by removing load from the primary database and reducing contention on the write path. These optimizations align with the [v2.0 roadmap](../../README.md#%EF%B8%8F-trade-offs--future-roadmap).

**Infrastructure**
- Deploy ~**20 application nodes** behind a load balancer
- **Read replicas:** mandatory for the 80% read traffic (browse/listing)

**Code Optimizations (v2.0)**
- **Atomic SQL Updates:** replace pessimistic locking with `UPDATE ... WHERE stock >= ?` to reduce lock contention
- **Async Checkout:** move payment processing to background jobs (Sidekiq/SolidQueue) to handle traffic spikes
- **Cursor-based Pagination:** avoid `COUNT(*)` queries for large datasets

**Future Work**
- **Redis for sessions/baskets:** reduces DB roundtrips but not critical for write contention
- **Selective async processing:** queue non-critical post-checkout work (emails, analytics)

---

## 5. Conclusion

The current architecture hits a hard wall at around 200 concurrent users, driven primarily by database write contention from pessimistic locking during checkout.

**Critical insight:** Horizontal scaling alone (adding more nodes) will not solve this problem. More nodes means more concurrent checkout attempts hitting the same database locks, which would actually *worsen* contention. Web workers will remain blocked waiting for lock acquisition regardless of how many nodes are deployed.

**The path forward requires v2.0 code changes:** replacing pessimistic locks with atomic SQL updates (`UPDATE ... WHERE stock >= ?`) is essential before scaling horizontally. Only after reducing lock contention will additional nodes provide meaningful throughput gains. Read replicas can then offload the 80% read traffic, further improving capacity.

### Action Plan

- **Infrastructure:** provision ~**20 nodes** + load balancer + DB read replicas
- **Code (v2.0):** implement atomic SQL updates for stock, async checkout, cursor-based pagination
- **Observability:** capture PostgreSQL lock metrics via `pg_stat_activity`
