# Load Test Summary

- **VUs (Virtual Users):** 200 (Peak: 250)
- **Dataset:** 10,000 products
- **Status:** FAILED (Thresholds crossed)

```bash
INFO[0000] Setup: ~10000 products, 500 pages (20/page)   source=console


  █ THRESHOLDS

    business_checkout_duration
    ✗ 'p(95)<1000' p(95)=11166.09655

    http_req_duration
    ✗ 'p(95)<500' p(95)=9.37s

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS

    checks_total.......: 21000  139.593906/s
    checks_succeeded...: 99.99% 20999 out of 21000
    checks_failed......: 0.00%  1 out of 21000

    ✓ setup: products fetched
    ✓ bootstrap add 201
    ✓ products show 200/304/404
    ✓ products index 200/304
    ✗ add/update 201
      ↳  99% — ✓ 2941 / ✗ 1
    ✓ basket show 200/304
    ✓ checkout 201

    CUSTOM
    business_basket_creations.......: 1226   8.149625/s
    business_checkout_duration......: avg=2907.275784 min=2013.657 med=2037.9925 max=16289.46 p(90)=3422.1097 p(95)=11166.09655
    business_successful_checkouts...: 992    6.59415/s

    HTTP
    http_req_duration...............: avg=1.01s       min=1.29ms   med=9.58ms    max=16.28s   p(90)=2.04s     p(95)=9.37s
      { expected_response:true }....: avg=1.01s       min=1.29ms   med=9.58ms    max=16.28s   p(90)=2.04s     p(95)=9.37s
    http_req_failed.................: 0.00%  1 out of 21000
    http_reqs.......................: 21000  139.593906/s

    EXECUTION
    iteration_duration..............: avg=1.01s       min=1.36ms   med=9.73ms    max=16.28s   p(90)=2.04s     p(95)=9.37s
    iterations......................: 20999  139.587258/s
    vus.............................: 2      min=0          max=241
    vus_max.........................: 250    min=250        max=250

    NETWORK
    data_received...................: 41 MB  273 kB/s
    data_sent.......................: 4.4 MB 29 kB/s



ERRO[0150] thresholds on metrics 'business_checkout_duration, http_req_duration' have been crossed
```
