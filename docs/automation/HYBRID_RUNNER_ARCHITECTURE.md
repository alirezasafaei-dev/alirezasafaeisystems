# Hybrid Runner Architecture

**Status:** Active
**Date:** 2026-07-07

## Overview

ASDEV automation runs across three execution environments:

| Environment | Role | When to Use |
|---|---|---|
| **VPS** | Always-on controller | Light tasks, monitoring, reporting, docs |
| **Local PC** | Heavy runner | GPU jobs, full builds, heavy tests, large refactors |
| **GitHub Actions** | Fallback scheduler | Cron triggers, CI/CD, heartbeat checks |

## VPS Role (Controller)

- Always-on (24/7)
- Runs autonomous loop every 30 minutes
- Processes light tasks: docs, test-only, reports, comments
- Posts to Issue #45
- Monitors health
- Handles network/retry logic
- Does NOT run heavy builds or GPU tasks

**Specs:** 2 vCPU / 4GB RAM / 50GB NVMe (minimum viable)

## Local PC Role (Heavy Runner)

- Manual trigger or scheduled
- Runs tasks marked `execution_target: local-heavy`
- Full builds, heavy tests, large refactors
- GPU-accelerated processing
- Local model tasks (OpenCode, Hermes)
- Available when developer is working

**Specs:** Whatever the developer's machine has

## GitHub Actions Role (Fallback)

- Cron schedule for heartbeat
- CI/CD pipeline
- Can trigger VPS or local jobs via webhook
- Fallback if VPS is down

## Task Routing

```
Task with execution_target: vps
  → VPS runs it automatically

Task with execution_target: local-heavy
  → VPS marks as needs-local-run
  → Posts command to Issue #45
  → Developer runs manually on local PC

Task with execution_target: github-actions
  → GitHub Actions handles it
```

## When to Upgrade VPS

Upgrade from controller to full runner if:
- VPS needs to run heavy tests regularly
- Build times are critical
- Multiple concurrent tasks needed
- Telegram bot + Docker/n8n added

**Upgrade path:** 2 vCPU → 4 vCPU, 4GB → 8GB RAM

## Heavy Job Handoff

1. VPS detects task with `execution_target: local-heavy`
2. VPS skips execution
3. VPS posts to Issue #45:
   ```
   Task A-Q15 requires local execution.
   Run locally: ./scripts/agent-command-center/local-heavy-runner.sh A-Q15
   ```
4. Developer runs command on local PC
5. Developer reports result
6. Queue updated

## Emergency Fallback

If VPS is down:
1. Local PC can run the full loop: `./scripts/agent-command-center/run-autonomous-loop.sh --issue 45 --max-jobs 3`
2. Local PC has all scripts via repo clone
3. Local timer can be re-enabled: `systemctl --user enable --now asdev-agent-loop.timer`
