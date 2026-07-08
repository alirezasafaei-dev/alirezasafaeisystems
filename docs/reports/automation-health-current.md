# AUTOMATION_HOST Health — Current

**Generated context:** 2026-07-08T22:35:00Z  
**Script:** `scripts/ops/automation-health-check.sh`

---

## Expected classification (from full audit)

```
CLASSIFICATION=DEGRADED_NON_BLOCKING
```

| Check | Result |
|-------|--------|
| Tools git/ssh/node/pnpm/docker | OK |
| Disk | ~48% · ~109G free |
| Memory available | ~19 GB |
| Docker unhealthy running | 0 |
| Docker exited leftovers | 5 (WARN) |
| PM2 apps | 0 (WARN idle) |
| Hermes gateway | running (observed) |
| OpenClaw gateway | running (observed) |
| IRAN SSH key | present |
| Control plane tree | created this transform |
| Queue | seeded `control-plane/queue/queue.json` |

---

## Score

**Overall ~7/10** — usable control plane; harden process governance next.

Re-run:

```bash
bash scripts/ops/automation-health-check.sh
# writes control-plane/health/last-health.json (gitignored)
```

Full audit: `docs/reports/automation-host-full-audit.md`
