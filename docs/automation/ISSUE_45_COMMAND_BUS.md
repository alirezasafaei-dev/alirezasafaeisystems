# Issue #45 Command Bus + Autonomous Watcher

**Status:** Active
**Date:** 2026-07-07

## Overview

Issue #45 is the single autonomous command bus and report bus for ASDEV automation. Users post commands as comments. The runner processes them and posts reports back. No manual copy-paste required.

## Command Syntax

| Command | Description |
|---|---|
| `[ASDEV STATUS]` | Post current status report |
| `[ASDEV STOP]` | Stop VPS timer |
| `[ASDEV SAFE-MODE]` | Re-enable VPS timer |
| `[ASDEV RUN <task>]` | Execute a specific task |
| `[ASDEV REPORT]` | Force status report |

## How It Works

### Command Processing
1. Runner polls Issue #45 comments every 30 minutes
2. Finds new comments since last processed comment ID
3. Parses commands from comment bodies
4. Executes approved commands
5. Posts execution report back to Issue #45
6. Tracks last processed comment ID in durable state

### Autonomous Watcher
1. Checks latest PRs in alirezasafaeisystems and auditsystems
2. Checks VPS timer status
3. Checks product blockers (PR #21)
4. Compares current state against last known state
5. Posts report ONLY when state changes
6. Stays silent when nothing changed (no spam)

## State Files

```
.state/asdev-agent-loop/
  state.json          — loop state (failures, last run)
  command-bus.json    — command bus state (last comment ID)
  watcher-state.json  — watcher state (PR hash, timer, blockers)
```

## Durable State

| Field | Description |
|---|---|
| last_comment_id | Last processed Issue #45 comment ID |
| last_report_at | Timestamp of last report posted |
| last_command | Last executed command |
| pr_hash | Hash of current open PR list |
| vps_timer | Last known VPS timer status |
| blocker_hash | Hash of current blocker list |
| last_successful_run | Timestamp of last successful loop run |

## Safety Rules

- Runner never prints secrets, tokens, IPs, or passwords
- Runner never edits PersianToolbox
- Runner never deploys to production
- Runner defers product-branch tasks until schema validation passes
- Runner posts clear error messages for blocked tasks
- Runner ignores duplicate commands (tracked by comment ID)
- Runner stays silent when nothing changes (no spam)

## Change Detection

The autonomous watcher computes hashes of:
- Open PR list (number + updatedAt)
- VPS timer status (active/inactive)
- Blocker list (PR #21 state)
- Last successful run timestamp

If any hash changes since last check, a report is posted.
If nothing changed, no report is posted.

## Cutover Flow

1. VPS timer runs automatically every 30 minutes
2. Runner detects VPS successful run
3. Runner posts to Issue #45:
   `VPS timer confirmed. Local fallback can be disabled.`
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
