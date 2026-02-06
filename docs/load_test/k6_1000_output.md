# Load Test Summary

- **VUs (Virtual Users):** 1000 (Peak: 1100)
- **Dataset:** 10,000 products
- **Status:** FAILED (Thresholds crossed)

```bash
  █ THRESHOLDS

    business_checkout_duration
    ✗ 'p(95)<1000' p(95)=5241.395

    http_req_duration
    ✗ 'p(95)<500' p(95)=3.31s

    http_req_failed
    ✗ 'rate<0.01' rate=22.93%


  █ TOTAL RESULTS

    checks_total.......: 61836  404.759791/s
    checks_succeeded...: 77.06% 47656 out of 61836
    checks_failed......: 22.93% 14180 out of 61836

    ✓ setup: products fetched
    ✗ bootstrap add 201
      ↳  74% — ✓ 3294 / ✗ 1112
    ✗ add/update 201
      ↳  78% — ✓ 6719 / ✗ 1868
    ✗ products show 200/304/404
      ↳  77% — ✓ 14191 / ✗ 4157
    ✗ products index 200/304
      ↳  77% — ✓ 14214 / ✗ 4214
    ✗ basket show 200/304
      ↳  75% — ✓ 6989 / ✗ 2213
    ✗ checkout 201
      ↳  78% — ✓ 2248 / ✗ 616

    CUSTOM
    business_basket_creations.......: 3294   21.56153/s
    business_checkout_duration......: avg=2052.531672 min=0        med=2020.946 max=29865.733 p(90)=2166.2047 p(95)=5241.395
    business_successful_checkouts...: 2248   14.714729/s

    HTTP
    http_req_duration...............: avg=615.38ms    min=0s       med=3.2ms    max=32.25s    p(90)=2.02s     p(95)=3.31s
      { expected_response:true }....: avg=778.68ms    min=496µs    med=4.15ms   max=32.25s    p(90)=2.31s     p(95)=3.56s
    http_req_failed.................: 22.93% 14180 out of 61836
    http_reqs.......................: 61836  404.759791/s

    EXECUTION
    dropped_iterations..............: 43164  282.538515/s
    iteration_duration..............: avg=2.35s       min=354.25µs med=6.28ms   max=32.25s    p(90)=7.77s     p(95)=7.77s
    iterations......................: 61835  404.753245/s
    vus.............................: 2      min=0              max=1100
    vus_max.........................: 1100   min=1050           max=1100

    NETWORK
    data_received...................: 93 MB  611 kB/s
    data_sent.......................: 10 MB  66 kB/s



ERRO[0153] thresholds on metrics 'business_checkout_duration, http_req_duration, http_req_failed' have been crossed
```
