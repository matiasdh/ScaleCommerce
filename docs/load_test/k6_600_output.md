# Load Test Summary

- **VUs (Virtual Users):** 600 (Peak: 700)
- **Dataset:** 10,000 products
- **Status:** FAILED (Thresholds crossed)

```bash
  █ THRESHOLDS

    business_checkout_duration
    ✗ 'p(95)<1000' p(95)=5505.3905

    http_req_duration
    ✗ 'p(95)<500' p(95)=3.56s

    http_req_failed
    ✗ 'rate<0.01' rate=13.94%


  █ TOTAL RESULTS

    checks_total.......: 50600  335.116859/s
    checks_succeeded...: 86.05% 43542 out of 50600
    checks_failed......: 13.94% 7058 out of 50600

    ✓ setup: products fetched
    ✗ bootstrap add 201
      ↳  85% — ✓ 2688 / ✗ 462
    ✗ basket show 200/304
      ↳  85% — ✓ 6523 / ✗ 1086
    ✗ products show 200/304/404
      ↳  86% — ✓ 12988 / ✗ 2077
    ✗ products index 200/304
      ↳  86% — ✓ 13228 / ✗ 2141
    ✗ add/update 201
      ↳  86% — ✓ 6091 / ✗ 964
    ✗ checkout 201
      ↳  86% — ✓ 2023 / ✗ 328

    CUSTOM
    business_basket_creations.......: 2688   17.802255/s
    business_checkout_duration......: avg=2249.503523 min=0        med=2024.589 max=24074.917 p(90)=3001.166 p(95)=5505.3905
    business_successful_checkouts...: 2023   13.398052/s

    HTTP
    http_req_duration...............: avg=579.26ms    min=0s       med=3.89ms   max=24.07s    p(90)=2.03s    p(95)=3.56s
      { expected_response:true }....: avg=672.94ms    min=502µs    med=4.67ms   max=24.07s    p(90)=2.49s    p(95)=3.67s
    http_req_failed.................: 13.94% 7058 out of 50600
    http_reqs.......................: 50600  335.116859/s

    EXECUTION
    dropped_iterations..............: 12400  82.123499/s
    iteration_duration..............: avg=1.71s       min=553.16µs med=6.02ms   max=24.07s    p(90)=7.77s    p(95)=7.77s
    iterations......................: 50599  335.110236/s
    vus.............................: 1      min=0             max=700
    vus_max.........................: 700    min=650           max=700

    NETWORK
    data_received...................: 86 MB  573 kB/s
    data_sent.......................: 9.1 MB 61 kB/s



ERRO[0151] thresholds on metrics 'business_checkout_duration, http_req_duration, http_req_failed' have been crossed
```
