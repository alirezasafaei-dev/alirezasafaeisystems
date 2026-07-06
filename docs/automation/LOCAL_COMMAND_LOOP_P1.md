# Local Command Loop — Phase P1

**Status:** Setup complete (2026-07-06)
**Scope:** Local-only, no production deploy
**Primary product:** ASDEV Audit Platform

---

## What Was Built

Phase P1 establishes the local foundation for MiMo + Hermes command loop:

1. **MiMo agent profiles** (`.mimocode/agents/`) — 5 role definitions
2. **Hermes profiles** (via `hermes profile create`) — 5 matching profiles
3. **Kanban board** `asdev-audit` — task queue for ASDEV work
4. **Dry-run task** — validated read-only execution
5. **Documentation** — handoff protocol, profile registry, this guide

---

## Setup Commands (reference)

### Create Hermes profiles

```bash
hermes profile create hermes-asdev-controller \
  --description "ASDEV task classifier and dispatcher. Routes kanban tasks to specialist profiles. Never edits PersianToolbox runtime."

hermes profile create hermes-asdev-reviewer \
  --description "Read-only code review and strategy pressure-testing for ASDEV Audit."

hermes profile create hermes-asdev-docs \
  --description "Long-context documentation, restructuring, and governance docs for ASDEV."

hermes profile create hermes-asdev-ops \
  --description "Workspace hygiene, doc sync, status updates. Local commands only."

hermes profile create hermes-asdev-code-draft \
  --description "Implementation drafts for auditsystems. No push without owner approval."
```

### Create kanban board

```bash
hermes kanban boards create asdev-audit --name "ASDEV Audit Command Loop"
hermes kanban boards use asdev-audit
```

### Dry-run task

```bash
hermes kanban create "Dry-run: Read command center docs and produce status report" \
  --body "Task: Read command center docs and produce a status report.
Repos: alirezasafaeisystems only.
Mode: read-only.
Expected output: report markdown.
ASDEV goal: Lower audit cost, support cost, or execution time." \
  --assignee hermes-asdev-docs \
  --workspace dir:/home/dev13/my-project/sites/live/alirezasafaeisystems
```

### Execute dry-run

```bash
hermes -z "Read docs/agent-command-center/README.md and docs/automation/README.md. Produce a 10-line status summary. Do not edit any files."
```

---

## Dry-Run Result

**Status:** ✅ Completed
**Date:** 2026-07-06
**Task ID:** t_98a0af1d (completed)
**Model used:** deepseek/deepseek-chat (OpenRouter/Gemini quota exhausted)

The dry-run validated:

- Hermes CLI accessible (`hermes -z` works)
- Kanban board `asdev-audit` exists with 1 completed task
- Profile `hermes-asdev-docs` exists
- Read-only execution completed without errors
- No files were edited
- No secrets were exposed

**Dry-run output:**

> 1. **Purpose**: Central hub for ASDEV Audit agent prompts and reports.
> 2. **Workflow**: Agents execute only approved tasks from `NEXT_AGENT_PROMPT.md` and report using `REPORT_TEMPLATE.md`.
> 3. **Constraints**: No runtime changes to PersianToolbox without explicit owner approval.
> 4. **Goals**: Tasks must directly support ASDEV Audit's 5 core objectives.
> 5. **Automation**: Monitors PR #42 for actionable prompts and ensures reports are logged before proceeding.

**Note:** OpenRouter default model (`owl-alpha`) routes to Gemini which had quota exhaustion. DeepSeek worked as fallback. Phase P2 should configure per-profile API keys.

---

## Command Loop Flow (Phase P1)

```text
1. Owner posts prompt on PR #42
2. MiMo reads prompt, classifies task
3. MiMo creates kanban task on asdev-audit board
4. MiMo assigns to correct Hermes profile
5. MiMo executes via `hermes -z` (oneshot)
6. Worker produces report
7. MiMo posts report to PR #42 via `gh pr comment`
8. MiMo updates STATE.json
9. MiMo stops, waits for next prompt
```

---

## What Phase P1 Does NOT Include

- GitHub API key in Hermes (deferred to P2)
- Hermes cron jobs (deferred to P2)
- Telegram approval gateway (deferred to P3)
- n8n dashboard (deferred to P4)
- Product code changes
- PersianToolbox changes
- Production deploy

---

## Next Phase (P2 — when approved)

- Wire monitor script → Hermes kanban create
- Add Hermes cron for PR #42 polling
- Configure GitHub token for `gh` in worker scripts
- Test full loop: prompt → kanban → dispatch → report → PR comment

---

## Files Created

| Path | Purpose |
|---|---|
| `.mimocode/agents/asdev-controller.md` | MiMo controller profile |
| `.mimocode/agents/asdev-reviewer.md` | MiMo reviewer profile |
| `.mimocode/agents/asdev-docs.md` | MiMo docs profile |
| `.mimocode/agents/asdev-ops.md` | MiMo ops profile |
| `.mimocode/agents/asdev-code-draft.md` | MiMo code draft profile |
| `docs/automation/MIMO_HANDOFF.md` | Handoff protocol |
| `docs/automation/MIMO_AGENT_PROFILES.md` | Profile registry |
| `docs/automation/LOCAL_COMMAND_LOOP_P1.md` | This file |

---

*Phase P1 complete. Awaiting owner approval for Phase P2 or next task.*
