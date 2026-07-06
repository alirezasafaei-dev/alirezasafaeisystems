# Issue #45 — Active Command Center

**Status:** Active (2026-07-06)
**Purpose:** Durable command thread for ASDEV automation
**Replaces:** PR #42 (historical)

---

## Thread

**Active:** [Issue #45](https://github.com/alirezasafaei-dev/alirezasafaeisystems/issues/45)
**Historical:** PR #42 (merged)

---

## Usage

### Monitor Issue #45

```bash
./scripts/agent-command-center/monitor-command-thread.sh --issue 45
```

### Run full loop

```bash
./scripts/agent-command-center/run-command-loop.sh --issue 45 --dry-run
```

### Post report to Issue #45

```bash
gh issue comment 45 --repo alirezasafaei-dev/alirezasafaeisystems --body-file /tmp/report.md
```

---

## Supported Thread Types

| Type | API | Command |
|---|---|---|
| Issue | `issues/{n}/comments` | `--issue 45` |
| PR | `issues/{n}/comments` | `--pr 42` |

---

## Config

```bash
export ASDEV_COMMAND_ISSUE=45
export ASDEV_COMMAND_REPO=alirezasafaei-dev/alirezasafaeisystems
```

---

## Scripts

| Script | Purpose |
|---|---|
| `monitor-command-thread.sh` | Monitor any thread (PR or Issue) |
| `run-command-loop.sh` | Unified loop entry point |
| `sync-github-to-kanban.sh` | Sync prompts to kanban |
| `dispatch-next-task.sh` | Dispatch next task |
| `collect-agent-report.sh` | Collect report |
| `post-agent-report.sh` | Post to thread |
| `update-command-state.sh` | Update STATE.json |

---

*Issue #45 is now the active command center.*
