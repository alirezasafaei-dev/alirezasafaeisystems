# Command Loop Runbook — ASDEV

**Purpose:** Step-by-step guide for running the MiMo/Hermes command loop
**Status:** Phase P2 (local-only)

---

## Prerequisites

1. Hermes installed (`hermes --version`)
2. `gh` CLI authenticated (`gh auth status`)
3. Kanban board exists (`hermes kanban boards list`)
4. Environment configured (`ops/hermes/.env`)

---

## Manual Loop (Single Task)

### Step 1: Check for pending prompts

```bash
cd sites/live/alirezasafaeisystems
./scripts/agent-command-center/monitor-pr.sh
```

Look for `STATUS: PROMPT_PENDING` in output.

### Step 2: Create kanban task

```bash
./scripts/agent-command-center/create-kanban-task.sh <prompt_comment_id> "<task_title>"
```

### Step 3: Execute task

```bash
./scripts/agent-command-center/dispatch-hermes-task.sh <task_id> "<prompt_text>"
```

### Step 4: Post report

```bash
./scripts/agent-command-center/post-agent-report.sh /tmp/agent-report.md
```

---

## Dry-Run (Full Loop Test)

```bash
cd sites/live/alirezasafaeisystems
./scripts/agent-command-center/dry-run-loop.sh
```

This runs the complete loop without touching product repos.

---

## Automated Loop (Cron)

### Setup Hermes cron

```bash
hermes cron create "0 * * * *" \
  "Run ASDEV PR monitor. If PROMPT_PENDING, create kanban task." \
  --name "asdev-pr42-watch" \
  --script /home/dev13/my-project/sites/live/alirezasafaeisystems/scripts/agent-command-center/dry-run-loop.sh
```

### Check cron status

```bash
hermes cron list
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `gh: not authenticated` | Run `gh auth login` |
| `hermes: command not found` | Check `~/.local/bin` in PATH |
| `kanban board not found` | Run `hermes kanban boards create asdev-audit` |
| `task creation fails` | Check `hermes kanban boards use asdev-audit` |
| `hermes -z fails` | Check API keys in `~/.hermes/config.yaml` |

---

## Safety Checklist

Before running the loop:

- [ ] No product repos will be edited
- [ ] No PersianToolbox changes will be made
- [ ] No deploy commands will execute
- [ ] No secrets will be committed
- [ ] NEXT_AGENT_PROMPT.md is not accidentally changed
- [ ] Dry-run completed successfully

---

*Runbook version: Phase P2 (2026-07-06)*
