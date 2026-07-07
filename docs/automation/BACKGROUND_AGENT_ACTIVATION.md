# Background Agent Activation Guide

**Status:** Ready to activate
**Date:** 2026-07-07

## What Was Built

Real autonomous execution loop that:
1. Reads pending tasks from `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md`
2. Runs safety gate (PersianToolbox, secrets, deploy, billing, frozen projects)
3. Creates branches for product work
4. Runs validations (typecheck, lint, test)
5. Posts execution reports
6. Continues to next task until stop gate or max-jobs reached

## Scripts

| Script | Purpose |
|---|---|
| `run-autonomous-loop.sh` | Main entry point — processes queue |
| `agent-safety-gate.sh` | Blocks dangerous operations |
| `claim-next-approved-task.sh` | Claims next pending task |
| `dispatch-product-worker.sh` | Dispatches worker with mode |
| `post-execution-report.sh` | Generates execution report |

## Usage

```bash
# Run 3 jobs
./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 3

# Run once
./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --once

# Dry run
./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --dry-run

# Run 10 jobs
./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 10
```

## Systemd Timer (persistent background)

```bash
# Copy timer files
cp ops/systemd/asdev-agent-loop.service ~/.config/systemd/user/
cp ops/systemd/asdev-agent-loop.timer ~/.config/systemd/user/

# Enable and start
systemctl --user daemon-reload
systemctl --user enable asdev-agent-loop.timer
systemctl --user start asdev-agent-loop.timer

# Check status
systemctl --user status asdev-agent-loop.timer
journalctl --user -u asdev-agent-loop -f
```

## Hermes Cron

```bash
# Register with Hermes (if available)
hermes cron add ops/hermes/asdev-command-loop-cron.json

# Check
hermes cron list
```

## Fallback: Shell Cron

```bash
# Add to crontab
crontab -e

# Add this line (every 30 minutes)
*/30 * * * * /home/dev13/my-project/scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 2 >> /home/dev13/my-project/ops/automation-logs/cron.log 2>&1
```

## Safety Gates

The loop automatically blocks:
- PersianToolbox edits (except read-only)
- Secret exposure
- Production deploys
- Billing/payment changes
- Frozen project edits
- Destructive git operations

## Queue Management

Edit `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md` to:
- Add new tasks
- Mark tasks complete
- Reprioritize tasks
- Block tasks

Format:
```markdown
- [ ] ID: A-Q01 | Task title | Repo: auditsystems | Mode: product-branch | Risk: low | Approval: auto | Validation: typecheck+lint+test | Stop Gates: test failure | Done: PR open
```
