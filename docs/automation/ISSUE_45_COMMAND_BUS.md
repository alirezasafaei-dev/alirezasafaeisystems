# Issue #45 Command Bus

**Status:** Active
**Date:** 2026-07-07

## Overview

Issue #45 is the single autonomous command bus for ASDEV automation. Users post commands as comments, and the runner processes them automatically.

## Command Syntax

| Command | Description |
|---|---|
| `[ASDEV STATUS]` | Post current status report |
| `[ASDEV STOP]` | Stop VPS timer |
| `[ASDEV SAFE-MODE]` | Re-enable VPS timer |
| `[ASDEV RUN <task>]` | Execute a specific task |
| `[ASDEV REPORT]` | Force report posting |

## How It Works

1. Runner polls Issue #45 comments every 30 minutes
2. Finds new comments since last processed
3. Parses commands from comment bodies
4. Executes approved commands
5. Posts execution report back to Issue #45
6. Tracks last processed comment ID in durable state

## Safety Rules

- Runner never prints secrets, tokens, IPs, or passwords
- Runner never edits PersianToolbox
- Runner never deploys to production
- Runner defers product-branch tasks until schema validation passes
- Runner posts clear error messages for blocked tasks
- Runner ignores duplicate commands (tracked by comment ID)

## State Files

```
.state/asdev-agent-loop/
  state.json          — loop state (failures, last run)
  command-bus.json    — command bus state (last comment ID)
```

## Status Report Format

The runner posts status reports in this format:

```markdown
**ASDEV Status Report** — 2026-07-07T19:00:00Z

| Component | Status |
|---|---|
| Timer | active |
| Linger | yes |
| Network | ok |
| GitHub auth | yes |
| Consecutive failures | 0 |
| Queue pending | 8 |
| Queue done | 12 |
| Last report | 2026-07-07T18:30:00Z |

Commands: `[ASDEV STATUS]` `[ASDEV STOP]` `[ASDEV SAFE-MODE]` `[ASDEV RUN <task>]`
```

## Cutover Flow

1. VPS timer runs automatically
2. Runner detects VPS successful run
3. Runner posts to Issue #45:
   ```
   VPS timer confirmed active. Local fallback can be disabled:
   systemctl --user stop asdev-agent-loop.timer
   systemctl --user disable asdev-agent-loop.timer
   ```
4. User disables local timer manually
5. Runner confirms local timer disabled

## Product Blocker Handling

- Product-branch tasks are deferred in safe mode
- Schema validation failure does not break VPS loop
- PR for schema fix is tracked separately
- Once schema PR merges, product-branch tasks resume

## Duplicate Prevention

- Runner tracks last processed comment ID
- Same comment is never processed twice
- Command state is durable across restarts
