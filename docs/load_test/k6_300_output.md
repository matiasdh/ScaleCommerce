# Load Test Summary

- **VUs (Virtual Users):** 300 (Peak: 350)
- **Dataset:** 10,000 products
- **Status:** FAILED (Thresholds crossed)

```bash
  █ THRESHOLDS

    business_checkout_duration
    ✗ 'p(95)<1000' p(95)=6924.1744

    http_req_duration
    ✗ 'p(95)<500' p(95)=4.95s

    http_req_failed
    ✗ 'rate<0.01' rate=5.67%


  █ TOTAL RESULTS

    checks_total.......: 29834  197.186208/s
    checks_succeeded...: 94.32% 28141 out of 29834
    checks_failed......: 5.67%  1693 out of 29834

    ✓ setup: products fetched
    ✗ bootstrap add 201
      ↳  92% — ✓ 1691 / ✗ 145
    ✗ products show 200/304/404
      ↳  94% — ✓ 8431 / ✗ 465
    ✗ products index 200/304
      ↳  94% — ✓ 8295 / ✗ 506
    ✗ add/update 201
      ↳  93% — ✓ 4069 / ✗ 271
    ✗ basket show 200/304
      ↳  94% — ✓ 4324 / ✗ 232
    ✗ checkout 201
      ↳  94% — ✓ 1330 / ✗ 74

    CUSTOM
    business_basket_creations.......: 1691   11.176573/s
    business_checkout_duration......: avg=2566.716242 min=0        med=2025.1595 max=16347.881 p(90)=3164.966 p(95)=6924.1744
    business_successful_checkouts...: 1330   8.790563/s

    HTTP
    http_req_duration...............: avg=748.19ms    min=0s       med=5.43ms    max=16.34s    p(90)=2.03s    p(95)=4.95s
      { expected_response:true }....: avg=792.51ms    min=686µs    med=5.95ms    max=16.34s    p(90)=2.05s    p(95)=5.01s
    http_req_failed.................: 5.67%  1693 out of 29834
    http_reqs.......................: 29834  197.186208/s

    EXECUTION
    dropped_iterations..............: 166    1.097168/s
    iteration_duration..............: avg=1.22s       min=759.95µs med=6.64ms    max=16.34s    p(90)=6.75s    p(95)=7.77s
    iterations......................: 29833  197.179599/s
    vus.............................: 1      min=0             max=399
    vus_max.........................: 400    min=350           max=400

    NETWORK
    data_received...................: 55 MB  365 kB/s
    data_sent.......................: 5.9 MB 39 kB/s



ERRO[0152] thresholds on metrics 'business_checkout_duration, http_req_duration, http_req_failed' have been crossed
```
