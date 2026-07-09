# ASDEV Current State

**Updated:** 2026-07-08T23:55:00Z  
**Mode:** Autonomous Productivity · Product quality loop
**Updated:** 2026-07-09T00:15:35Z

---

## Platform

| Item | Value |
|------|-------|
| SoT | GitHub `main` |
| Workspace | `/home/dev13/ASDEV` |
| Control plane | `control-plane/` live |
| Productivity mode | ENABLED |

## CRITICAL_SITE (`persiantoolbox`)

| Item | Value |
|------|-------|
| Prod app-layer | LIVE on IRAN `:3100` pin family fcc7192 · **product GitHub main advanced** (`0c16bec` quality+SEO factory) — redeploy gated |
| Product score | ~7.5/10 est. · **not 10/10** until public edge + CWV + verified reviews |
| Staging | LIVE legacy `:3000` · same pin |
| Public edge | **OFF** (not claimed live; no public nginx/SSL edge yet) |
| Product quality | Packs on product GitHub `main` at `bc1068c` + **upcoming SEO factory** work |
| Score trajectory | **~7.5 / 10** — not 10/10 until public edge + depth + uptime are proven |
| Rollback history | none (first prod) |
| Meta backup | IRAN daily 03:15 UTC · FRESH |

## AUTOMATION_HOST

| Item | Value |
|------|-------|
| Class | DEGRADED_NON_BLOCKING |
| Gateways | Hermes + OpenClaw running (outside PM2) |
| PM2 | idle |
| Docker | 1 healthy + exited legacy inventory |

## Gated (not running)

- Public edge  
- Live monitoring timers  
- Migrations  
- Production redeploy  

## Active build focus

**ASDEV Engineering Operating System** (governance, memory, registry, deploy model, observability prep) — not daily hygiene thrash.

**Quality note:** Product-side quality packs advance trust/report depth on github main; public score remains ~7.5 until edge is live and measured. Do not claim 10/10 or public prod edge deploy until edge + depth + uptime are proven.
