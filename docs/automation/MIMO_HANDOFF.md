# MiMo Handoff Protocol — ASDEV Command Loop

**Status:** Phase P1 (local-only)
**Purpose:** How MiMo sessions hand off to Hermes profiles and back

---

## Handoff Flow

```text
Owner prompt (PR #42 or NEXT_AGENT_PROMPT.md)
  → MiMo reads prompt, classifies task
  → MiMo creates kanban task on asdev-audit board
  → MiMo assigns to appropriate Hermes profile
  → Hermes worker executes in worktree
  → Worker posts report to PR #42
  → MiMo reviews report, updates state
  → Owner provides next prompt
```

## MiMo → Hermes Handoff

When MiMo spawns a Hermes worker:

1. Create kanban task with body including:
   - `repo_scope` (which repos)
   - `product_goal` (ASDEV Audit goal)
   - `approval_required` (true/false)
   - `owner_approved` (false by default)
   - `protected_repos` (persiantoolbox always)
   - `validation_commands` (per repo)

2. Assign to correct profile:
   - Code work → `hermes-asdev-code-draft`
   - Review → `hermes-asdev-reviewer`
   - Docs → `hermes-asdev-docs`
   - Ops → `hermes-asdev-ops`
   - Classification → `hermes-asdev-controller`

3. Execute via `hermes -z` or kanban dispatch

## Hermes → MiMo Return

After worker completes:

1. Worker posts `# Agent Execution Report` to PR #42
2. MiMo reads report, validates schema
3. MiMo updates `STATE.json`
4. MiMo waits for next owner prompt

## Session Resume

MiMo can resume previous context via:
- `memory` tool (session checkpoint)
- `STATE.json` (last handled prompt/report)
- PR #42 comments (full history)

## PersianToolbox Guard

Every handoff checks:

```
IF repo_scope includes persiantoolbox AND NOT owner_approved_persiantoolbox
  → BLOCK task
  → Report to PR #42
  → Wait for owner approval
```

No exceptions.
