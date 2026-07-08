# AUTOMATION_HOST Status — Latest

**Date:** 2026-07-08T21:12:00Z  
**Host role:** OWNER_PC colocated with AUTOMATION_HOST executor  
**Path:** `/home/dev13/ASDEV` → mother repo checkout

---

## Classification

**DEGRADED_NON_BLOCKING**

| Signal | Status | Blocking? |
|--------|--------|-----------|
| git/bash/ssh/node/pnpm/curl/rsync | OK | No |
| docker | OK (optional) | No |
| pm2 | Idle 0 processes (expected) | No |
| ASDEV repo + registry + deploy scripts | OK | No |
| Disk | ~48% used, >100GB free | No |
| Memory | ~18GB available | No |
| Unhealthy docker (running) | 0 | No |
| Legacy exited containers | halo-secret-*, others | No |
| Self-hosted GitHub Actions runner | **Absent** | No (executor path is SSH/local) |

---

## Checker output (after false-positive fix)

Runner detection previously used `pgrep -af` and could match the checker argv itself.  
Fixed to `pgrep -x Runner.Listener`.

Expected classification after fix:

- WARN: PM2 idle  
- WARN: no GHA runner  
- **DEGRADED_NON_BLOCKING** (still usable as deploy orchestrator)

---

## Executor capability proven this session

| Capability | Evidence |
|------------|----------|
| SSH to IRAN_PROD | Live staging deploy executed |
| Prepare site source | `sites/live/persiantoolbox` ready |
| Run deploy engine | Staging release activated |
| Monitoring scripts | Host/disk checks runnable |

---

## Recommended non-blocking follow-ups

1. Optional: install self-hosted runner only if GHA infra recovery requires it  
2. Optional: PM2 ecosystem only if a long-running orchestrator process is defined  
3. Do **not** restart legacy exited Docker without need  

---

## Not done

- Live monitoring timers (`APPROVE_MONITORING_LIVE_TIMERS`)  
- Production deploy  
