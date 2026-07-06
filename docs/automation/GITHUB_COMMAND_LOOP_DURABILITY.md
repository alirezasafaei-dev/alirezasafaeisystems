# GitHub Command Loop — Durability Design

**Status:** Phase P2+ (2026-07-06)
**Purpose:** Make the command loop self-sustaining without manual relay

---

## Problem

The command loop currently requires manual steps:
1. Owner posts prompt on PR #42
2. Agent manually runs monitor
3. Agent manually creates kanban task
4. Agent manually dispatches
5. Agent manually posts report

**Goal:** Automate steps 2-5 so the owner only needs to post prompts and review reports.

---

## Durable Loop Architecture

```text
┌──────────────┐     gh api           ┌─────────────────┐
│  PR #42      │ ◄───────────────────│ monitor-pr.sh   │
│  comments    │                      └────────┬────────┘
└──────┬───────┘                               │
       │ PROMPT_PENDING                        ▼
       ▼                              ┌─────────────────┐
┌──────────────┐   sync               │ sync-github-to- │
│ Owner prompt │ ───────────────────► │ kanban.sh       │
└──────────────┘                      └────────┬────────┘
                                               │
                                               ▼
                                      ┌─────────────────┐
                                      │ Hermes kanban   │
                                      │ board: asdev    │
                                      └────────┬────────┘
                                               │ dispatch
                                               ▼
                                      ┌─────────────────┐
                                      │ dispatch-next-  │
                                      │ task.sh         │
                                      └────────┬────────┘
                                               │
                                               ▼
                                      ┌─────────────────┐
                                      │ collect-agent-  │
                                      │ report.sh       │
                                      └────────┬────────┘
                                               │
                                               ▼
                                      ┌─────────────────┐
                                      │ post-agent-     │
                                      │ report.sh       │
                                      └────────┬────────┘
                                               │
                                               ▼
                                      ┌─────────────────┐
                                      │ update-command- │
                                      │ state.sh        │
                                      └────────┬────────┘
                                               │
                                               ▼
                                      ┌─────────────────┐
                                      │ Owner reviews   │
                                      │ posts next      │
                                      │ prompt          │
                                      └─────────────────┘
```

---

## Scripts

| Script | Purpose | Idempotent |
|---|---|---|
| `monitor-pr.sh` | Detect prompts/reports | ✅ |
| `sync-github-to-kanban.sh` | Create kanban task from prompt | ✅ |
| `dispatch-next-task.sh` | Execute next ready task | ✅ |
| `collect-agent-report.sh` | Format task output as report | ✅ |
| `post-agent-report.sh` | Post report to PR #42 | ✅ |
| `update-command-state.sh` | Update STATE.json | ✅ |

---

## Idempotency

All scripts are idempotent:
- Monitor: reads state, doesn't modify PR
- Sync: checks if task already exists for prompt ID
- Dispatch: only claims ready tasks
- Collect: generates report from output
- Post: posts to PR (duplicate posts are visible but harmless)
- Update: overwrites STATE.json atomically

---

## State Management

### STATE.json

```json
{
  "lastCheckedAt": "2026-07-06T20:00:00Z",
  "lastHandledPromptCommentId": "4896439275",
  "lastReportCommentId": "4896479350"
}
```

### Hermes Kanban

- Board: `asdev-audit`
- Tasks: ready → running → done/blocked
- Claims: atomic via `hermes kanban claim`

### GitHub Labels (optional, future)

```
agent-idle
agent-running
prompt-needed
owner-approval-needed
protected-repo
validation-failed
```

---

## Cron Integration

### Hermes Cron (Phase P3)

```bash
hermes cron create "0 * * * *" \
  "Run ASDEV command loop: monitor → sync → dispatch → report" \
  --name "asdev-command-loop" \
  --script /path/to/scripts/agent-command-center/dry-run-loop.sh
```

### GitHub Action (existing)

- Runs hourly
- Warns if prompt pending
- Does not execute agents

---

## Dry-Run Mode

Every script supports `--dry-run`:

```bash
./sync-github-to-kanban.sh --dry-run
./dispatch-next-task.sh --dry-run
./collect-agent-report.sh <id> <file> --dry-run
./update-command-state.sh <id> <id> --dry-run
```

---

## Failure Handling

| Failure | Recovery |
|---|---|
| Monitor fails | Check `gh auth status`, retry |
| Kanban task creation fails | Check `hermes kanban boards use asdev-audit` |
| Dispatch fails | Task stays ready, retry next cycle |
| Report posting fails | Report saved locally, retry |
| STATE.json update fails | File may be locked, retry |

---

## Files

| File | Purpose |
|---|---|
| `scripts/agent-command-center/monitor-pr.sh` | Monitor PR #42 |
| `scripts/agent-command-center/sync-github-to-kanban.sh` | Sync prompts to kanban |
| `scripts/agent-command-center/dispatch-next-task.sh` | Dispatch next task |
| `scripts/agent-command-center/collect-agent-report.sh` | Collect report |
| `scripts/agent-command-center/post-agent-report.sh` | Post to PR #42 |
| `scripts/agent-command-center/update-command-state.sh` | Update state |
| `scripts/agent-command-center/create-kanban-task.sh` | Create task (P2) |
| `scripts/agent-command-center/dispatch-hermes-task.sh` | Execute task (P2) |
| `scripts/agent-command-center/dry-run-loop.sh` | Dry-run test (P2) |

---

*Durability design complete. All scripts support --dry-run and are idempotent.*
