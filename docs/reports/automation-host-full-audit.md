# AUTOMATION_HOST Full Audit

**Date:** 2026-07-08T22:30:27Z  
**Host alias:** AUTOMATION_HOST (colocated with OWNER_PC on hostname `asdev`)  
**User:** `dev13`  
**Workspace:** `/home/dev13/ASDEV` → `/home/dev13/alirezasafaeisystems`  
**Mode:** Read-only  

---

## CURRENT STATE

### Hardware / OS

| Item | Value |
|------|-------|
| OS | Ubuntu 24.04.4 LTS (noble) |
| Kernel | 6.17.0-35-generic x86_64 |
| CPU | Intel i5-10400 · **12** threads |
| RAM | 23920 MB total · **~19347 MB** available |
| Swap | 8191 MB · 0 used |
| Disk `/` | 216G · **48%** used · **~109G free** |
| Load | 0.68 / 0.60 / 0.48 |
| Uptime | ~9.5h (session sample) |

### Role mapping

| Alias | Reality on this box |
|-------|---------------------|
| OWNER_PC | Desktop session (Chrome, GNOME) present |
| AUTOMATION_HOST | Same machine — orchestration tools + ASDEV checkout |
| IRAN_PROD | Remote VPS (SSH key `asdev_vps_ed25519` present) |

### Tooling

| Tool | Status |
|------|--------|
| git 2.43 / node v24.18 / pnpm 9.15 | OK |
| bash, ssh, rsync, curl, jq | OK |
| docker 29.1.3 | OK · containerd running |
| pm2 | Installed · **0 processes** |
| ASDEV repo + registry + deploy scripts | OK |
| Private secrets tree | `ASDEV_PRIVATE/` (outside git) |

### Services (selected)

Running: `docker`, `cron`, `containerd`, `ollama`, desktop stack, `happd`.  
User processes of interest:

| Process | Role |
|---------|------|
| `hermes_cli.main gateway run` | Hermes agent gateway |
| `openclaw … gateway --port 18789` | OpenClaw gateway |
| `grok` CLI session | Interactive agent (this loop) |

### systemd (ASDEV units in repo)

Under `ops/systemd/`: `asdev-agent-loop.service/.timer`, portfolio units, openclaw unit examples.  
**Not verified as enabled system-wide** in this audit (desktop host; no blind enable).

### Cron / timers

| Scope | State |
|-------|-------|
| User crontab (`dev13`) | **empty** |
| System timers | standard Ubuntu (apt, logrotate, fstrim, …) |
| IRAN_PROD meta backup cron | separate host (03:15 UTC) — not on this host |

### Docker summary

| Name | Status | Decision class |
|------|--------|----------------|
| modular-monolith-postgres | Up (healthy) | keep (active microcatalog) |
| persiantoolbox-postgres | Exited 0 · 10d | archive/document (not CRITICAL_SITE prod path) |
| halo-secret-redis | Exited 0 · 4w | archive/legacy |
| halo-secret-db | Exited 0 · 4w | archive/legacy |
| practical_edison | Exited 1 · 13d | archive/unknown one-off |
| elated_hofstadter | Exited 1 · 13d | archive/unknown one-off |

No **running unhealthy** containers.

### PM2

Empty process list — no unmanaged PM2 apps. Matches policy “idle OK until ecosystem defined”.

### Repository / automation surface

| Area | State |
|------|-------|
| `docs/automation/` | 57 files (memory, hermes, queues, doctrine) |
| `scripts/agent-command-center/` | 22 scripts (loops, dispatch, safety gate) |
| Deploy engine | present |
| Monitoring scripts | present |
| GitHub fetch | intermittent TLS failures observed (infra) |

### SSH / IRAN

| Check | Result |
|-------|--------|
| `~/.ssh/asdev_vps_ed25519` | present |
| Proven capability | CRITICAL_SITE staging + prod app-layer orchestration from this host |

---

## HEALTH SCORE

| Dimension | Score (0–10) | Notes |
|-----------|--------------|-------|
| Compute / disk | **9** | Plenty of RAM/disk |
| Core tooling | **9** | Full toolchain |
| ASDEV repo readiness | **9** | Registry + deploy OK |
| Orchestration structure | **5** | Scripts exist; control-plane dirs not yet formalized |
| Agent process governance | **4** | Hermes/OpenClaw run outside PM2 policy |
| Docker hygiene | **6** | One healthy app DB; five stopped leftovers |
| Self-monitoring | **5** | Readiness script exists; full control-plane health new |
| Secrets hygiene | **8** | Private tree separate; do not regress |
| IRAN reachability | **8** | Key present; ops proven |
| **Overall** | **7.0 / 10** | **DEGRADED_NON_BLOCKING → usable control plane with gaps** |

```
CLASSIFICATION=DEGRADED_NON_BLOCKING
USABLE_AS_CONTROL_PLANE=YES_WITH_HARDENING
```

---

## PROBLEMS

1. **No formal control-plane directory contract** on host (agents/queue/state/logs).  
2. **Hermes + OpenClaw** run as ad-hoc user services — not registered in PM2 policy / agent registry.  
3. **PM2 empty** while long-running gateways exist elsewhere → split-brain process model.  
4. **Stopped Docker leftovers** (halo-secret, anonymous exited) clutter inventory.  
5. **No self-hosted GHA runner** (optional; local executor path works).  
6. **GitHub TLS flakiness** on fetch/API (non-blocking for local work).  
7. **OWNER_PC + AUTOMATION_HOST colocated** — desktop load (Chrome) competes with automation CPU/RAM.  
8. **Duplicate/overlapping automation docs** in `docs/automation/` (many Hermes/phase docs).  

---

## RISKS

| Risk | Severity | Mitigation |
|------|----------|------------|
| Desktop reboot kills gateways | Medium | Document restart; later systemd user units |
| Accidental production action from this host | High | Approval phrases + safety gates already required |
| Secret leakage into git | High | Keep `ASDEV_PRIVATE`; scan before commit |
| Legacy Docker volumes forgotten | Low | Inventory + archive policy (no blind delete) |
| Queue without durable state | Medium | Local queue under control-plane (this transform) |
| Colocation: human vs automation | Medium | Accept for now; split host later if needed |

---

## RECOMMENDED ARCHITECTURE

See `docs/architecture/automation-control-plane.md`.

Summary:

```
GitHub (SoT: code, docs, memory, roadmaps)
        │
        ▼
AUTOMATION_HOST control plane
  control-plane/{agents,queue,scheduler,runners,reports,logs,state,health}
  scripts/control-plane/* + scripts/agent-command-center/*
  scripts/ops/automation-health-check.sh
        │ SSH / rsync (no secrets in logs)
        ▼
IRAN_PROD (CRITICAL_SITE runtime only)
```

**Do not** move production runtime onto AUTOMATION_HOST.

---

## Related reports

- `docs/reports/automation-health-current.md`  
- `docs/reports/container-inventory.md`  
- `docs/reports/automation-host-status-latest.md` (prior)  
