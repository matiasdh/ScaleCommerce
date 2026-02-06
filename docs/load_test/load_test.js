import http from "k6/http";
import { check, group } from "k6";
import { randomIntBetween, randomItem } from "https://jslib.k6.io/k6-utils/1.4.0/index.js";
import { Counter, Trend } from "k6/metrics";

const successfulCheckouts = new Counter("business_successful_checkouts");
const basketCreations = new Counter("business_basket_creations");
const checkoutDuration = new Trend("business_checkout_duration");

export const options = {
  scenarios: {
    load_test: {
      executor: "ramping-arrival-rate",
      startRate: 0,
      timeUnit: "1s",
      preAllocatedVUs: 1050,
      maxVUs: 1100,
      stages: [
        { duration: "30s", target: 500 },
        { duration: "30s", target: 1000 },
        { duration: "1m", target: 1000 },
        { duration: "30s", target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<500"],
    business_checkout_duration: ["p(95)<1000"],
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000/api/v1";
const PAGE_SIZE = parseInt(__ENV.PAGE_SIZE || "20", 10);

const READ_RATIO = parseFloat(__ENV.READ_RATIO || "0.8");
// Writes: by default 75% add, 25% checkout => overall 15% add, 5% checkout
const CHECKOUT_RATIO_WITHIN_WRITES = parseFloat(__ENV.CHECKOUT_RATIO_WITHIN_WRITES || "0.25");
// 5% of checkouts will use a failing token to test error handling
const PAYMENT_FAILURE_RATIO = parseFloat(__ENV.PAYMENT_FAILURE_RATIO || "0.05");

// Product IDs range: 1 to 10,000 (consecutive)
const MIN_PRODUCT_ID = parseInt(__ENV.MIN_PRODUCT_ID || "1", 10);
const MAX_PRODUCT_ID = parseInt(__ENV.MAX_PRODUCT_ID || "10000", 10);

// Per-VU state
let basketId = null;
let basketHasItems = false;

// Per-VU validators cache
const etagCache = new Map();

// Shared data from setup
let maxPage = 1;

export function setup() {
  // Fetch first page to get per_page from API response
  const res = http.get(`${BASE_URL}/products?page=1`);
  check(res, { "setup: products fetched": (r) => r.status === 200 });

  const body = JSON.parse(res.body);
  const perPage = body.per_page || PAGE_SIZE;
  const totalProducts = MAX_PRODUCT_ID - MIN_PRODUCT_ID + 1;

  const calculatedMaxPage = Math.ceil(totalProducts / perPage);
  console.log(`Setup: ~${totalProducts} products, ${calculatedMaxPage} pages (${perPage}/page)`);

  return { maxPage: calculatedMaxPage };
}

// Returns a random product ID in the configured range
function randomProductId() {
  return randomIntBetween(MIN_PRODUCT_ID, MAX_PRODUCT_ID);
}

function getBasketIdFromResponse(res) {
  return (
    res.headers["shopping-basket-id"] ||
    res.headers["Shopping-Basket-ID"] ||
    res.headers["Shopping-Basket-Id"] ||
    null
  );
}

function getEtagFromResponse(res) {
  return res.headers["etag"] || res.headers["ETag"] || res.headers["Etag"] || null;
}

function authHeaders() {
  const h = { "Content-Type": "application/json" };
  if (basketId) h["Authorization"] = `Bearer ${basketId}`;
  return h;
}

function conditionalGet(url, cacheKey, headers, tagName) {
  const h = { ...(headers || {}) };
  const cachedEtag = etagCache.get(cacheKey);
  if (cachedEtag) h["If-None-Match"] = cachedEtag;

  const res = http.get(url, {
    headers: h,
    tags: { name: tagName },
  });

  // Update cache if 200
  if (res.status === 200) {
    const etag = getEtagFromResponse(res);
    if (etag) etagCache.set(cacheKey, etag);
  }

  return res;
}

// Bootstrap basket: POST /shopping_basket/products without Authorization
function ensureBasket() {
  if (basketId) return true;

  const pid = randomProductId();
  const payload = JSON.stringify({ product: { product_id: pid, quantity: 1 } });

  const res = http.post(`${BASE_URL}/shopping_basket/products`, payload, {
    headers: { "Content-Type": "application/json" },
    tags: { name: "BOOTSTRAP POST /shopping_basket/products" },
  });

  const ok = check(res, { "bootstrap add 201": (r) => r.status === 201 });
  if (ok) {
    basketCreations.add(1);
  } else {
    return false;
  }

  const id = getBasketIdFromResponse(res);
  if (!id) return false;

  basketId = id;
  basketHasItems = true;

  // This response also includes an etag
  const etag = getEtagFromResponse(res);
  if (etag) etagCache.set(`basket:${basketId}`, etag);

  return true;
}

function readFlow(data) {
  const headers = authHeaders();
  const choice = Math.random();

  if (choice < 0.4) {
    const page = randomIntBetween(1, data.maxPage);
    const url = `${BASE_URL}/products?page=${page}`;
    const res = conditionalGet(url, `products:index:${page}`, headers, "GET /products (etag)");
    check(res, { "products index 200/304": (r) => r.status === 200 || r.status === 304 });
    return;
  }

  if (choice < 0.8) {
    const pid = randomProductId();
    const url = `${BASE_URL}/products/${pid}`;
    const res = conditionalGet(url, `products:show:${pid}`, headers, "GET /products/:id (etag)");
    check(res, { "products show 200/304/404": (r) => [200, 304, 404].includes(r.status) });
    return;
  }

  // basket show
  const url = `${BASE_URL}/shopping_basket`;
  const res = conditionalGet(url, `basket:${basketId}`, headers, "GET /shopping_basket (etag)");
  check(res, { "basket show 200/304": (r) => r.status === 200 || r.status === 304 });
}

function writeFlow() {
  const headers = authHeaders();
  const doCheckout = Math.random() < CHECKOUT_RATIO_WITHIN_WRITES;

  if (doCheckout && basketHasItems) {
    // 5% of checkouts simulate payment failure
    const token = Math.random() < PAYMENT_FAILURE_RATIO ? "tok_failure" : "tok_success";
    const payload = JSON.stringify({
      payment_token: token,
      email: `user-${__VU}-${Date.now()}@example.com`,
      address: {
        line_1: "123 Test St",
        city: "Load Town",
        state: "TS",
        zip: "00000",
        country: "US",
      },
    });

    const res = http.post(`${BASE_URL}/shopping_basket/checkout`, payload, {
      headers,
      tags: { name: "POST /shopping_basket/checkout" },
    });

    check(res, { "checkout 201": (r) => r.status === 201 });
    checkoutDuration.add(res.timings.duration);

    if (res.status === 201) {
      // New cycle after checkout
      successfulCheckouts.add(1);
      basketId = null;
      basketHasItems = false;
    } else {
      // Log failure for debugging
      console.warn(`Checkout failed: ${res.status} - ${res.body}`);
      // Basket likely mutated or error; invalidate cached validators
      etagCache.delete(`basket:${basketId}`);
    }

    return;
  }

  // Add/update product (default write) with variable quantity
  const pid = randomProductId();
  const qty = randomIntBetween(1, 5);
  const payload = JSON.stringify({ product: { product_id: pid, quantity: qty } });

  const res = http.post(`${BASE_URL}/shopping_basket/products`, payload, {
    headers,
    tags: { name: "POST /shopping_basket/products" },
  });

  check(res, { "add/update 201": (r) => r.status === 201 });

  if (res.status === 201) {
    basketHasItems = true;
    // Invalidate basket ETag after write so next GET doesn't use stale validator
    etagCache.delete(`basket:${basketId}`);
  }
}

export default function (data) {
  // If no basket session, bootstrap first
  if (!basketId) {
    group("Init basket", () => ensureBasket());
    return;
  }

  if (Math.random() < READ_RATIO) {
    group("Read", () => readFlow(data));
  } else {
    group("Write", () => writeFlow());
  }
}
