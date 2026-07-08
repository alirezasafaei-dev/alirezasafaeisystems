# AUTOMATION_HOST Pre-Repair Snapshot

**Date:** 2026-07-08
**Classification:** DEGRADED
**Status:** Before repair

---

## Host Identity

| Field | Value |
|-------|-------|
| Hostname | asdev |
| OS | Ubuntu 24.04.4 LTS |
| Kernel | Linux 6.17.0-35-generic |

---

## Uptime / Load

| Metric | Value |
|--------|-------|
| Uptime | 6h 54m |
| Load avg | 0.68 / 0.55 / 0.59 |

---

## Disk / Memory

| Resource | Total | Used | Available |
|----------|-------|------|-----------|
| Memory | 23920 MB | 5895 MB | 18025 MB |
| Disk (/) | 216G | 96G | 110G (47%) |

---

## PM2 Status

- PM2 God Daemon: Running
- Processes managed: 0 (empty)
- Startup script: Not installed

---

## Docker Status

| Container | Status | Health |
|-----------|--------|--------|
| modular-monolith-postgres | Running | Healthy |
| halo-secret-redis | Exited | Unhealthy |
| halo-secret-db | Exited | Unhealthy |
| practical_edison | Exited | - |
| elated_hofstadter | Exited | - |
| persiantoolbox-postgres | Exited | - |

---

## Systemd Failed Units

- snap.network-manager.networkmanager.service (failed)

---

## Automation Processes

- hermes-agent: Running (Python gateway)
- openclaw: Running (Node.js gateway)
- No ASDEV-specific PM2 processes

---

## Classification

**DEGRADED** — Host operational, but:
- PM2 manages 0 processes
- 2 Docker containers unhealthy (legacy, non-ASDEV)
- No ASDEV automation processes configured
