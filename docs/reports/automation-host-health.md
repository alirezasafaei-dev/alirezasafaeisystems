# AUTOMATION_HOST Health — Post Production App-Layer

**Date:** 2026-07-08T22:18:12Z  
**Host role:** OWNER_PC / local executor (this session)  
**Script:** `scripts/monitoring/check-automation-host-readiness.sh`  
**Classification:** **DEGRADED_NON_BLOCKING**

---

## Summary

| Area | Result |
|------|--------|
| Critical tools | PASS (git, bash, ssh, node, pnpm, curl, rsync, docker, pm2) |
| ASDEV repo path | PASS |
| Deploy registry + scripts | PASS |
| Disk free | PASS (~111 GB free, ~48% used) |
| Memory available | PASS (~19 GB) |
| Unhealthy docker | PASS (none) |
| PM2 processes | WARN — idle (0); non-blocking |
| Self-hosted GHA runner | WARN — absent; not required for local executor path |

```
CLASSIFICATION=DEGRADED_NON_BLOCKING
ERRORS=0
WARNINGS=2
```

---

## Orchestration inventory (safe audit)

| Component | State | Action taken |
|-----------|-------|--------------|
| Deploy engine scripts | Present in repo | none required |
| Monitoring foundation scripts | Present + new app-layer/deploy checks | docs + scripts added this loop |
| PM2 ecosystem for ASDEV | Not configured | leave idle (policy) |
| Docker | No unhealthy running | leave legacy alone |
| Cron local | not required for this loop | no install |
| Hermes/OpenCode docs | present under `docs/automation/` | no destructive change |
| IRAN_PROD SSH key | present locally (`asdev_vps_ed25519`) | never commit |

---

## Safe repairs performed this loop

- None required on host processes.  
- Documentation and monitoring scripts only.  
- **Did not** restart docker, install timers, or alter PM2.

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| PM2 idle | Low | Only needed if long-running worker required |
| No self-hosted runner | Low | Use local executor + IRAN remote build |
| GHA infra historically flaky | Medium | Merge on local CI Router evidence when needed |
| Secrets only in private env files | Info | Keep outside git (`ASDEV_PRIVATE`) |

---

## Next healthy actions (optional, gated)

1. `APPROVE_MONITORING_LIVE_TIMERS` — install non-mutating check timers  
2. Optional ASDEV PM2 ecosystem if a durable worker is defined  
3. Self-hosted runner only if GHA continues to block and owner wants it  

---

## Status code

```
AUTOMATION_HOST=DEGRADED_NON_BLOCKING
executor_path=USABLE
blocking=false
```
