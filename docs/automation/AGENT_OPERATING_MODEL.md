# ASDEV Agent Operating Model

**Status:** Active
**Date:** 2026-07-07

## Agents

### 1. VPS Runner (Primary Executor)

- **Role:** Scheduled safe-mode execution
- **Location:** VPS (Ubuntu 24.04, 2 vCPU, 4GB RAM)
- **User:** asdev
- **Timer:** asdev-agent-loop.timer (every 30min)
- **Modes:** read-only, docs-only, automation-script
- **Does NOT:** product-branch, test-only (until validation clean)
- **Reports to:** Issue #45

### 2. Hermes (Watcher/Coordinator)

- **Role:** Validates status, escalates blockers
- **Location:** VPS or local
- **Function:** Monitors Issue #45, validates runner health
- **Reports to:** Issue #45

### 3. MiMo (Implementation Agent)

- **Role:** Opens PRs, fixes automation
- **Location:** Developer machine
- **Function:** Implements code changes, creates focused PRs
- **Reports to:** Issue #45

### 4. ChatOps Bot (Status Interface)

- **Role:** Read-only Telegram status
- **Location:** VPS (separate openclaw user)
- **Function:** Answers status queries via Telegram
- **Does NOT:** execute commands, create PRs, deploy
- **Reports to:** Telegram + Issue #45

## Communication Protocol

All agents communicate through Issue #45:

```
Agent → Issue #45: [ASDEV REPORT] status update
Owner → Issue #45: [ASDEV STATUS] or [ASDEV STOP]
Runner → Issue #45: execution results
Bot → Telegram: status summary
```

## Safety Rules

1. PersianToolbox: read-only, never edit
2. Deploy: never automatic, owner approval required
3. Billing/schema: never auto-merge
4. Secrets: never print or commit
5. Product-branch: deferred until validation clean

## Escalation Path

```
Runner detects blocker → posts [OWNER ACTION REQUIRED] to Issue #45
Hermes validates → confirms or escalates
Owner reviews → approves or rejects
MiMo implements → opens PR
Runner validates → merges if safe
```
