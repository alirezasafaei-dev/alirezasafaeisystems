# ASDEV Current State

**Updated:** 2026-07-08T23:15:00Z  
**Mode:** Autonomous Productivity · OS Build Loop v2

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
| Prod app-layer | LIVE `20260708T221124Z-fcc7192` · pin `fcc7192` · `:3100` |
| Staging | LIVE legacy `:3000` · same pin |
| Public edge | OFF |
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
