# Decision Log

Append-only. Newest first.

---

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
