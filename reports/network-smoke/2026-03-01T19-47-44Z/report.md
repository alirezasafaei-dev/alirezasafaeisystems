# Network Smoke Matrix (2026-03-01T19-47-44Z)

Scenarios: 3
Targets per scenario: 3

| Scenario | Target | HTTP | BodyLen t0/t1s/t5s | CSP | PageErr | Proxy | Result | Failure |
|---|---|---:|---:|---:|---:|---|---|---|
| direct-chromium | https://persiantoolbox.ir/ | 504 | 295/295/295 | 0 | 0 | no | FAIL | http:504 |
| direct-chromium | https://alirezasafaeisystems.ir/ | 504 | 307/307/307 | 0 | 0 | no | FAIL | http:504 |
| direct-chromium | https://audit.alirezasafaeisystems.ir/ | 504 | 319/319/319 | 0 | 0 | no | FAIL | http:504 |
| proxy-chromium-http-127-0-0-1-10808 | https://persiantoolbox.ir/ | 504 | 295/295/295 | 0 | 0 | yes | FAIL | http:504 |
| proxy-chromium-http-127-0-0-1-10808 | https://alirezasafaeisystems.ir/ | 504 | 307/307/307 | 0 | 0 | yes | FAIL | http:504 |
| proxy-chromium-http-127-0-0-1-10808 | https://audit.alirezasafaeisystems.ir/ | 504 | 319/319/319 | 0 | 0 | yes | FAIL | http:504 |
| proxy-chromium-socks5-127-0-0-1-10808 | https://persiantoolbox.ir/ | 504 | 295/295/295 | 0 | 0 | yes | FAIL | http:504 |
| proxy-chromium-socks5-127-0-0-1-10808 | https://alirezasafaeisystems.ir/ | 504 | 307/307/307 | 0 | 0 | yes | FAIL | http:504 |
| proxy-chromium-socks5-127-0-0-1-10808 | https://audit.alirezasafaeisystems.ir/ | 504 | 319/319/319 | 0 | 0 | yes | FAIL | http:504 |

Total checks: 9
Failed checks: 9
JSON: /home/dev/Project_Me_All/Project_Me/alirezasafaeisystems/reports/network-smoke/2026-03-01T19-47-44Z/result.json