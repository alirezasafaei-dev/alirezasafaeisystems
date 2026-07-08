# AUTOMATION_HOST Read-Only Audit Report

**Date:** 2026-07-08 15:53 EDT
**Classification:** DEGRADED
**Auditor:** MiMoCode (read-only, no mutations)

---

## 1. Host Identity

| Field | Value |
|-------|-------|
| Hostname | `asdev` |
| OS | Ubuntu 24.04.4 LTS |
| Kernel | Linux 6.17.0-35-generic |
| Architecture | x86-64 |
| Hardware | ASUS PRIME H410M-K R2.0 (desktop) |
| Firmware | 2802 (2021-11-30, ~4y 7mo old) |

---

## 2. Uptime / Load

| Metric | Value |
|--------|-------|
| Uptime | 6h 47m |
| Users logged in | 1 |
| Load avg (1/5/15) | 0.71 / 0.49 / 0.61 |

**Status:** Healthy. Load is well below core count (12 cores detected).

---

## 3. Disk / Memory

### Disk
| Filesystem | Size | Used | Avail | Use% | Mount |
|------------|------|------|-------|------|-------|
| /dev/mapper/ubuntu--vg-ubuntu--lv | 216G | 96G | 110G | 47% | / |
| /dev/sda2 | 2.0G | 221M | 1.6G | 13% | /boot |
| /dev/sda1 | 1.1G | 6.2M | 1.1G | 1% | /boot/efi |
| /dev/sdb1 (ext) | 110G | 36G | 68G | 35% | /media/dev13/128G |

**Status:** Healthy. Root at 47%, external drive at 35%.

### Memory
| Type | Total | Used | Free | Available |
|------|-------|------|------|-----------|
| RAM | 23,920 MB | 5,877 MB | 6,608 MB | 18,042 MB |
| Swap | 8,191 MB | 0 MB | 8,191 MB | - |

**Status:** Healthy. 75% RAM available, no swap usage.

---

## 4. Running Automation Processes

Key automation-related processes detected:

| Process | PID | Status | Notes |
|---------|-----|--------|-------|
| `happd` (Happ Process Control Daemon) | 1847 | Running | Service active |
| `Happ` (user agent) | 12953 | Running | User-level process |
| `xray` (proxy core) | 14709 | Running | Proxy for outbound traffic |
| `ollama serve` | 3565 | Running | AI inference, CPU-only (no GPU) |
| `dockerd` | 3563 | Running | Container engine |
| `containerd` | 1876 | Running | Container runtime |
| `PM2 God Daemon` | 63904 | Running | No managed processes |
| `hermes-cli gateway` | 2036 | Running | Messaging platform integration |
| `openclaw gateway` | 2037 | Running | Gateway on port 18789 |
| `mimocode` (this session) | 57532 | Running | Current audit session |

---

## 5. GitHub Runner Status

**Not detected.** No GitHub Actions runner process found in `ps aux` output.

---

## 6. Agent Loop Status

| Agent | Status | Notes |
|-------|--------|-------|
| Hermes Gateway | Running | User service, PID 2036 |
| OpenClaw Gateway | Running | User service, port 18789, PID 2037 |
| PM2 | Running | God daemon active, **zero managed processes** |

**Observation:** PM2 is running but has no processes under management. If staging workflows depend on PM2-managed services, they will not execute.

---

## 7. Docker / Podman Containers

### Docker
| Container | Image | Status | Health | Ports |
|-----------|-------|--------|--------|-------|
| `modular-monolith-postgres` | postgres:16-alpine | Running (7h) | Healthy | 5432 |
| `halo-secret-redis` | - | Exited | **Unhealthy** | - |
| `halo-secret-db` | - | Exited | **Unhealthy** | - |

**Docker version:** 29.1.3
**Containerd:** Active

**Issue:** Two containers (`halo-secret-redis`, `halo-secret-db`) are exited and unhealthy. These may need `docker compose up` or manual intervention.

### Podman
Not available on this host.

---

## 8. Active Timers / Cron

### System Timers (18 total)
All standard Ubuntu maintenance timers. No custom automation timers detected.

Key timers:
- `apt-daily.timer` / `apt-daily-upgrade.timer` — package updates
- `fwupd-refresh.timer` — firmware updates
- `logrotate.timer` — log rotation
- `sysstat-collect.timer` — system stats

### User Cron
**Empty.** No crontab entries for user `dev13`.

---

## 9. Relevant Logs Summary

### Docker Service
- Last boot: 2026-07-08 09:05 — clean startup
- Previous shutdown: Graceful (signal terminated)
- Container `modular-monolith-postgres` restored successfully
- Minor warnings: "failed to determine if container is already mounted" (cosmetic, resolved)

### Ollama Service
- Version: 0.20.2
- Listening on port 11434
- **GPU not detected** — falling back to CPU inference (23.4 GiB RAM available)
- Warning: "user overrode visible devices" (HSA_OVERRIDE_GFX_VERSION=8.0.3 set but no GPU found)
- 0 blobs/models loaded

---

## 10. Blocked / Failing Services

| Service | State | Notes |
|---------|-------|-------|
| `snap.network-manager.networkmanager` | **Failed** | Snap network-manager service failed |

This is a snap-based NetworkManager service. The system NetworkManager (`NetworkManager.service`) is running normally, so this may be a redundant snap service. No impact on connectivity detected.

---

## 11. ASDEV Path References

| Path | Target | Git Status |
|------|--------|------------|
| `/home/dev13/ASDEV` | Symlink → `/home/dev13/alirezasafaeisystems` | On branch `main`, up to date with `origin/main`, clean |

**Status:** ASDEV repo is synced to main, working tree clean. No stale references detected.

---

## 12. Staging Workflow Readiness

### Ready
- [x] Host online and stable (6h 47m uptime)
- [x] Disk space sufficient (110G free on root)
- [x] Memory sufficient (18G available)
- [x] Docker engine running
- [x] PostgreSQL container healthy (port 5432)
- [x] ASDEV repo on main, clean
- [x] Ollama service running (CPU mode)
- [x] Hermes/OpenClaw gateways running

### Degraded
- [ ] PM2 has zero managed processes (may need `pm2 startup` + process restoration)
- [ ] Two Docker containers unhealthy (`halo-secret-redis`, `halo-secret-db`)
- [ ] No GPU for Ollama inference (CPU-only)
- [ ] No GitHub Actions runner detected

### Classification

## **DEGRADED**

The host is operational and can execute staging workflows, but has degraded components:
1. Two unhealthy Docker containers need recovery
2. PM2 process list is empty
3. No GPU acceleration for AI workloads

**Recommended actions (not executed during this audit):**
1. Investigate `halo-secret-redis` and `halo-secret-db` container health
2. Restore PM2-managed processes if needed for staging
3. Verify GPU driver status if GPU inference is required
