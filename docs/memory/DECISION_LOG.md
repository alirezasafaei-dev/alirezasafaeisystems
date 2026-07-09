# Decision Log

Append-only. Newest first.

---

## 2026-07-08 — No 10/10 or public-edge claim until proven

- **Decision:** Do **not** claim 10/10 product/site quality or production **public** deploy (edge live) until **public edge + depth + uptime** are proven.  
- **Why:** App-layer prod on `:3100` + product quality packs (`bc1068c` + SEO factory) improve the product, but public edge is still OFF; score trajectory is ~7.5 not 10.  
- **Not doing yet:** Marketing 10/10 claims, edge cutover, or treating app-layer-only as full public launch.

## 2026-07-08 — OS Build Loop v2

- **Decision:** Build ASDEV Engineering Operating Model before more site handwork.  
- **Why:** Multi-project + multi-agent growth needs factory, not one-off ops.  
- **Not doing yet:** public edge / live timers / migrations without phrases.

## 2026-07-08 — Autonomous Productivity Mode

- **Decision:** Agents must continue safe high-value work; stop only on real gates.  
- **Why:** Over-gating created a conservative waiter, not an OS builder.

## 2026-07-08 — First CRITICAL_SITE production = app-layer only

- **Decision:** Option A — `127.0.0.1:3100` only.  
- **Why:** Blast radius; edge separate phrase.

## 2026-07-08 — Port isolation 3100/3200

- **Decision:** Registry prod/staging ports never equal.  
- **Why:** Co-host safety.

## 2026-07-08 — Remote build on IRAN for product pin

- **Decision:** Build on IRAN (heap + swap) instead of huge SCP.  
- **Why:** Transfer instability / OOM.
