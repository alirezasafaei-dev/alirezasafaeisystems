# ASDEV Chain of Command

**Status:** Active
**Date:** 2026-07-08

## Architecture

```text
Owner
  ↓ goals, approvals, red lines

MiMo = Commander / Governor / Product Brain
  ↓ roadmap, backlog, task assignment, PRs, validation, merge, deploy

OpenCode = Worker (fast implementation)
Codex = Reviewer (critical/security/schema review)
Grok = Scout (risk discovery, architecture stress-test)
Hermes/VPS = Scheduler + Monitor (always-on)

  ↓ all report to

Issue #45 = Command Center + Report Bus

  ↓ status display only

Telegram Bot = Status UI (no execution authority)
ChatGPT = External hourly auditor (not core brain)
```

## Agent Roles

| Agent | Role | Authority | Reports To |
|---|---|---|---|
| MiMo | Commander/Governor | Full roadmap, task assignment, PR creation, merge low-risk, deploy with gates | Issue #45 |
| OpenCode | Worker | Small/medium code patches, fast fixes | MiMo via Issue #45 |
| Codex | Reviewer | Critical review, security, schema, deploy review | MiMo via Issue #45 |
| Grok | Scout | Risk discovery, architecture review, growth ideas | MiMo via Issue #45 |
| Hermes/VPS | Scheduler | Monitoring, validation, health checks, deploy checks | Issue #45 |
| Telegram Bot | Status UI | Read-only status display | Telegram + Issue #45 |
| ChatGPT | External Auditor | Hourly monitoring, corrective commands | Issue #45 |

## Decision Flow

1. Owner sets goal/approval → MiMo receives
2. MiMo creates sprint → assigns tasks to agents
3. Agents execute → report to Issue #45
4. MiMo validates → merges if safe
5. MiMo deploys if gates pass
6. MiMo posts report → continues to next sprint
7. Telegram bot shows status to owner
8. ChatGPT monitors hourly and issues corrections if needed

## Hard Rules

- PersianToolbox: read-only, never edit
- Deploy: only when gates pass, owner approval documented
- Billing/Schema: only with explicit owner approval
- Secrets: never print or commit
- No paid API dependency
- No destructive DB work without backup
