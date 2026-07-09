# ASDEV Control Plane (repo tree)

Runtime + contract for AUTOMATION_HOST orchestration.

**Governance (mandatory):**  
[`docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md`](../docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md)

Architecture: `docs/architecture/automation-control-plane.md`

```
agents/      agent profiles
queue/       queue.json + schema
scheduler/   timer examples (not auto-installed)
runners/     runner definitions
reports/     local copies (gitignored bodies)
logs/        runtime logs (gitignored)
state/       local state (gitignored)
backups/     CP config backups (gitignored)
health/      last-health.json (gitignored)
docs/        local notes
```

## Quick commands

```bash
bash scripts/ops/automation-health-check.sh
bash scripts/control-plane/queue-list.sh
bash scripts/control-plane/loop-once.sh
```
