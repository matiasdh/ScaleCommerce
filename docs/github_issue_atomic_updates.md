# feat: Add CheckoutOrderAtomicService with batch stock reservation

## Summary

New `CheckoutOrderAtomicService` using atomic SQL (`UPDATE ... WHERE stock >= ?`) instead of pessimistic locking. One batch UPDATE per cart. Ref: [Load Test Report](load_test/load_test_results.md)

## Problem

`CheckoutOrderService` holds product locks during payment auth. At 200 VUs: p95 = 9.37s.

## Solution

Batch `UPDATE ... FROM (VALUES ...)` for whole cart. No product locks. Same interface as `CheckoutOrderService`.

## Steps

- [ ] **1.** Create `CheckoutOrderAtomicService`
- [ ] **2.** Add specs
- [ ] **3.** Update README
