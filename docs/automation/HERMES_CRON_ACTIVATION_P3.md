# Hermes Cron Activation — Phase P3

**Status:** Dry-run setup (not live)
**Date:** 2026-07-06
**Purpose:** Prepare scheduled checking without manual relay

---

## Current State

- Hermes v0.17.0 installed
- Kanban board `asdev-audit` active
- Command loop scripts ready
- Issue #45 as active thread

---

## Cron Setup (Dry-Run Only)

### Create cron job (disabled)

```bash
hermes cron create "0 * * * *" \
  "ASDEV command loop: monitor Issue #45, sync to kanban if prompt pending" \
  --name "asdev-issue45-watch" \
  --script /home/dev13/my-project/sites/live/alirezasafaeisystems/scripts/agent-command-center/run-command-loop.sh \
  --deliver log
```

### Enable cron (when approved)

```bash
hermes cron resume asdev-issue45-watch
```

### Disable cron

```bash
hermes cron pause asdev-issue45-watch
```

---

## Dry-Run Simulation

```bash
./scripts/agent-command-center/run-command-loop.sh --issue 45 --dry-run
```

---

## Safety

- Cron only monitors, does not execute
- Tasks remain in `ready` status until dispatched
- PersianToolbox protection enforced
- No auto-approval, no auto-deploy

---

*Cron activation design complete. Not deployed — requires owner approval.*
