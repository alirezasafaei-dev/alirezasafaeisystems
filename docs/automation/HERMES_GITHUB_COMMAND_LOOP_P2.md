# Hermes GitHub Command Loop — Phase P2

**Status:** Implementation complete (2026-07-06)
**Scope:** Local-only command loop bridge
**Primary product:** ASDEV Audit Platform

---

## What Was Built

Phase P2 wires the GitHub PR #42 command thread to the local Hermes kanban system:

1. **Monitor script** — detects actionable prompts (existing, unchanged)
2. **Create kanban task** — converts monitor output to Hermes task
3. **Dispatch worker** — executes task via `hermes -z` (oneshot)
4. **Post report** — sends report to PR #42 via `gh`
5. **Dry-run test** — validates full loop end-to-end

---

## Command Loop Flow

```text
┌──────────────┐     gh api           ┌─────────────────┐
│  PR #42      │ ◄───────────────────│ monitor-pr.sh   │
│  comments    │                      └────────┬────────┘
└──────┬───────┘                               │
       │ PROMPT_PENDING                        ▼
       ▼                              ┌─────────────────┐
┌──────────────┐   create task        │ create-kanban-  │
│ Owner prompt │ ───────────────────► │ task.sh         │
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
                                      │ dispatch-hermes- │
                                      │ task.sh         │
                                      │ (hermes -z)     │
                                      └────────┬────────┘
                                               │
                                               ▼
                                      ┌─────────────────┐
                                      │ post-agent-     │
                                      │ report.sh       │
                                      │ (gh pr comment) │
                                      └────────┬────────┘
                                               │
                                               ▼
                                      ┌─────────────────┐
                                      │ Owner / ChatGPT │
                                      │ next prompt     │
                                      └─────────────────┘
```

---

## Scripts

| Script | Purpose | Usage |
|---|---|---|
| `monitor-pr.sh` | Detect prompts/reports | `./monitor-pr.sh` |
| `create-kanban-task.sh` | Create Hermes task | `./create-kanban-task.sh <id> <title>` |
| `dispatch-hermes-task.sh` | Execute task | `./dispatch-hermes-task.sh <task_id> [prompt]` |
| `post-agent-report.sh` | Post to PR #42 | `./post-agent-report.sh <report_file>` |
| `dry-run-loop.sh` | End-to-end test | `./dry-run-loop.sh` |

---

## Environment Configuration

Copy `ops/hermes/env.example` to `ops/hermes/.env` and configure:

```bash
cp ops/hermes/env.example ops/hermes/.env
# Edit .env with your values (never commit .env)
```

Required for full loop:
- `GITHUB_TOKEN` — or use `gh auth login`
- `HERMES_KANBAN_BOARD` — defaults to `asdev-audit`

---

## Safety Rules

1. **No auto-approval** — every task requires owner prompt
2. **No product edits** — scripts only read product repos
3. **No PersianToolbox** — protected, read-only
4. **No deploy** — scripts never run deploy commands
5. **No secrets** — env.example has placeholders only
6. **Dry-run first** — always test with `dry-run-loop.sh` before production use

---

## Dry-Run Validation

The `dry-run-loop.sh` script validates:

- Monitor script runs and detects status
- Kanban task creation works
- Hermes execution via `hermes -z` works
- Task completion works
- No product files are edited
- No PersianToolbox files are touched
- No deploy commands are executed

---

## Files Created

| Path | Purpose |
|---|---|
| `scripts/agent-command-center/create-kanban-task.sh` | Create kanban task from prompt |
| `scripts/agent-command-center/dispatch-hermes-task.sh` | Execute kanban task |
| `scripts/agent-command-center/post-agent-report.sh` | Post report to PR #42 |
| `scripts/agent-command-center/dry-run-loop.sh` | End-to-end dry-run test |
| `ops/hermes/env.example` | Environment configuration template |
| `docs/automation/HERMES_GITHUB_COMMAND_LOOP_P2.md` | This file |
| `docs/automation/COMMAND_LOOP_RUNBOOK.md` | Step-by-step runbook |
| `docs/automation/SECRETS_AND_TOKENS_POLICY.md` | Token handling policy |

---

## Next Phase (P3 — when approved)

- Hermes cron job for hourly monitoring
- Telegram approval gateway
- Per-profile API keys

---

*Phase P2 complete. Awaiting owner approval for push or Phase P3.*
