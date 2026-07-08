# ASDEV Automation Control Plane Architecture

**Version:** 1.0  
**Last Updated:** 2026-07-08  
**Host:** AUTOMATION_HOST  
**SoT:** GitHub `alirezasafaei-dev/alirezasafaeisystems`

---

## Mission

AUTOMATION_HOST is the **central orchestration layer** for ASDEV — not a place to run random scripts.

Responsibilities:

| Domain | Responsibility |
|--------|----------------|
| Agents | identity, permissions, dispatch, logs |
| Queues | task lifecycle, priority, dependencies |
| Scheduler | approved recurring jobs only |
| Health | self + IRAN probes (read-only by default) |
| Deploy orchestration | preflight/deploy **with phrases** |
| Reporting | docs/reports + control-plane/reports |
| Repo sync | fetch/push GitHub; rsync platform scripts to IRAN |
| Memory | AGENT_MEMORY + handoff + queue state |

**Not** responsible for: serving CRITICAL_SITE public traffic (that is IRAN_PROD + edge).

---

## Directory contract

### In Git (template + durable config)

```
/home/dev13/ASDEV/control-plane/
  README.md
  agents/           # registry snippets / profiles (no secrets)
  queue/            # example + committed schema; live may be local-only
  scheduler/        # cron/timer examples (not auto-installed)
  runners/          # runner definitions
  reports/          # generated report copies (optional; prefer docs/reports)
  logs/             # .gitkeep only — runtime logs gitignored
  state/            # machine-local state samples; live state often gitignored
  backups/          # control-plane config backups (no secrets)
  health/           # last health JSON snapshots (optional)
  docs/             # control-plane local notes
```

### On host (runtime, may be same tree)

Preferred runtime root (may equal repo path):

```
$ASDEV_ROOT/control-plane/
```

Optional external runtime (if logs must leave git tree):

```
/home/dev13/asdev-control-plane-runtime/
```

---

## Logical architecture

```
                 ┌─────────────────────────────┐
                 │  GitHub (SoT)               │
                 │  code · docs · memory · PR  │
                 └──────────────┬──────────────┘
                                │ git pull/push
                 ┌──────────────▼──────────────┐
                 │  AUTOMATION_HOST            │
                 │  control-plane engine       │
                 │                             │
                 │  ┌─────────┐  ┌──────────┐  │
                 │  │ agents  │  │  queue   │  │
                 │  └────┬────┘  └────┬─────┘  │
                 │       │            │        │
                 │  ┌────▼────────────▼─────┐  │
                 │  │ loop engine / runners │  │
                 │  └────┬────────────┬─────┘  │
                 │       │            │        │
                 │  health        reports      │
                 └───────┬────────────┬────────┘
                         │ SSH        │
                         ▼            ▼
                   IRAN_PROD     docs/reports (git)
```

---

## Data flow (one autonomous cycle)

1. **Read state** — `AGENT_MEMORY.md`, queue JSON, health snapshot  
2. **Select task** — highest priority approved / safe-autonomous  
3. **Safety gate** — block prod/edge/migration without phrase  
4. **Execute** — runner or agent-command-center script  
5. **Validate** — health checks / tests / dry-run  
6. **Report** — `docs/reports/*` + control-plane log line  
7. **Memory** — append decisions/blockers  
8. **Continue or stop** — stop only on approval gate or real blocker  

---

## Permission model

| Action class | Autonomous? | Gate |
|--------------|-------------|------|
| Audit / docs / scripts | YES | none |
| Local health checks | YES | none |
| IRAN read-only status | YES | SSH key |
| Staging deploy | NO | `APPROVE_PHASE_2_STAGING_DEPLOY` |
| Production app deploy | NO | `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` |
| Public edge | NO | `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` |
| Live monitoring timers | NO | `APPROVE_MONITORING_LIVE_TIMERS` |
| Migrations | NO | `APPROVE_CRITICAL_SITE_MIGRATION` |
| Delete containers / PM2 kill | NO | explicit owner approval |

---

## Integration points

| Component | Path |
|-----------|------|
| Agent command center | `scripts/agent-command-center/` |
| Control plane CLIs | `scripts/control-plane/` |
| Deploy engine | `scripts/deploy/asdev-*.sh` |
| Host health | `scripts/ops/automation-health-check.sh` |
| Monitoring probes | `scripts/monitoring/` |
| Memory | `docs/automation/AGENT_MEMORY.md` |
| Queue system | `docs/automation/TASK_QUEUE_SYSTEM.md` |
| Agent registry | `docs/automation/AGENT_REGISTRY.md` |

---

## Success criteria

- Any new agent/session reads **AGENT_MEMORY** + **AGENT_REGISTRY** first  
- Tasks have IDs, status, logs, results in queue store  
- Production mutations impossible without phrase checks  
- Health check produces machine-readable status  
- One batched PR per major control-plane phase  
