# Network Smoke Matrix (2026-02-28T05-04-57Z)

Scenarios: 3
Targets per scenario: 3

| Scenario | Target | HTTP | BodyLen t0/t1s/t5s | CSP | PageErr | Proxy | Result | Failure |
|---|---|---:|---:|---:|---:|---|---|---|
| direct-chromium | https://persiantoolbox.ir/ | 200 | 2867/2867/0 | 0 | 0 | no | FAIL | white-screen-after-load |
| direct-chromium | https://alirezasafaeisystems.ir/ | 200 | 6190/6190/6190 | 0 | 0 | no | PASS | none |
| direct-chromium | https://audit.alirezasafaeisystems.ir/ | 200 | 2265/2265/2265 | 0 | 0 | no | PASS | none |
| proxy-chromium-http-127-0-0-1-10808 | https://persiantoolbox.ir/ | 200 | 2867/2867/0 | 0 | 0 | yes | FAIL | white-screen-after-load |
| proxy-chromium-http-127-0-0-1-10808 | https://alirezasafaeisystems.ir/ | 200 | 6190/6190/6190 | 0 | 0 | yes | PASS | none |
| proxy-chromium-http-127-0-0-1-10808 | https://audit.alirezasafaeisystems.ir/ | 200 | 2265/2265/2265 | 0 | 0 | yes | PASS | none |
| proxy-chromium-socks5-127-0-0-1-10808 | https://persiantoolbox.ir/ | 200 | 2867/2903/2902 | 0 | 0 | yes | PASS | none |
| proxy-chromium-socks5-127-0-0-1-10808 | https://alirezasafaeisystems.ir/ | 200 | 6190/6190/6190 | 0 | 0 | yes | PASS | none |
| proxy-chromium-socks5-127-0-0-1-10808 | https://audit.alirezasafaeisystems.ir/ | 200 | 2265/2265/2265 | 0 | 0 | yes | PASS | none |

Total checks: 9
Failed checks: 2
JSON: /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems/reports/network-smoke/2026-02-28T05-04-57Z/result.json