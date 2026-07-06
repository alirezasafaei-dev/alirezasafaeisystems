# Hermes Cron — Command Loop Polling

**Status:** Design only (not deployed)
**Purpose:** Automate periodic PR #42 monitoring

---

## Design

### Cron Job

```bash
hermes cron create "0 * * * *" \
  "ASDEV command loop: monitor PR #42, sync to kanban if prompt pending" \
  --name "asdev-pr42-watch" \
  --script /home/dev13/my-project/sites/live/alirezasafaeisystems/scripts/agent-command-center/sync-github-to-kanban.sh \
  --deliver log
```

### Schedule

- **Frequency:** Every hour (`0 * * * *`)
- **Script:** `sync-github-to-kanban.sh`
- **Mode:** Read-only monitoring + task creation
- **Execution:** Does NOT auto-dispatch (requires manual or separate cron)

### Safety

- Cron only creates kanban tasks, does not execute them
- Tasks remain in `ready` status until manually or separately dispatched
- PersianToolbox protection enforced by task body template
- No auto-approval, no auto-deploy

---

## Setup Commands

```bash
# Create cron job
hermes cron create "0 * * * *" \
  "ASDEV command loop monitor" \
  --name "asdev-pr42-watch" \
  --script /home/dev13/my-project/sites/live/alirezasafaeisystems/scripts/agent-command-center/sync-github-to-kanban.sh

# List cron jobs
hermes cron list

# Run once manually
hermes cron tick asdev-pr42-watch

# Pause
hermes cron pause asdev-pr42-watch

# Resume
hermes cron resume asdev-pr42-watch
```

---

## Dry-Run Cron Simulation

```bash
# Simulate what cron would do
./scripts/agent-command-center/sync-github-to-kanban.sh --dry-run
```

---

## Limitations

1. Cron runs in Hermes context, not shell context
2. `gh` CLI auth must be available in Hermes environment
3. State file updates must be atomic to avoid races
4. No Telegram/email notifications yet (Phase P3)

---

*Cron design complete. Not deployed — requires owner approval.*
