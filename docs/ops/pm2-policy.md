# PM2 Policy — AUTOMATION_HOST

**Version:** 1.0  
**Last Updated:** 2026-07-08  
**Status:** Active policy (no unmanaged ASDEV processes via PM2)

---

## Current state

- `pm2 list` → **empty** (0 processes)  
- Long-running gateways observed **outside** PM2:
  - Hermes gateway (python)  
  - OpenClaw gateway (node :18789)  

---

## Goals

1. **No unmanaged ASDEV process** without registry entry  
2. Clear ownership, restart, logging, monitoring  
3. Do **not** delete/kill processes without approval  

---

## Ownership

| Process class | Owner agent | Manager |
|---------------|-------------|---------|
| Deploy one-shots | deploy-agent | bash (not PM2) |
| Control-plane loops | automation-host-agent | systemd user timer **or** PM2 (choose one) |
| Hermes gateway | hermes-gateway | document restart; optional PM2 later |
| OpenClaw gateway | openclaw-gateway | document restart; optional PM2 later |
| CRITICAL_SITE runtime | IRAN_PROD | **not** PM2 on AUTOMATION_HOST |

---

## Rules

1. Before `pm2 start`, add agent to `AGENT_REGISTRY.md` and ecosystem file under `control-plane/runners/`.  
2. Prefer **explicit ecosystem file** over ad-hoc CLI.  
3. Logs: `~/.pm2/logs/` or redirected under `control-plane/logs/` (gitignored).  
4. Restart policy: `exp_backoff` for gateways; never `autorestart` on failing secret-dependent one-shots.  
5. Monitoring: include PM2 status in `automation-health-check.sh`.  
6. **Idle PM2 is OK** if no ASDEV ecosystem is defined (current).  

---

## Prohibited without approval

- `pm2 delete all`  
- Killing Hermes/OpenClaw PIDs “to clean up”  
- Running CRITICAL_SITE Next server on AUTOMATION_HOST under PM2  

---

## Future ecosystem (not installed)

```javascript
// control-plane/runners/ecosystem.config.cjs (example only)
module.exports = {
  apps: [
    // only after owner approval to daemonize control plane
    // { name: 'asdev-queue-worker', script: 'scripts/control-plane/loop-once.sh' }
  ]
}
```

Install requires owner decision — not part of this transform loop.
