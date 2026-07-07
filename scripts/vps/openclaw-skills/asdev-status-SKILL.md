# ASDEV Status Skill (Phase 1 — Read-Only, No LLM)

Read-only skill that queries ASDEV Issue #45 status and recent PRs.
Phase 1 uses GitHub API only — no LLM required.

## Phase 1 Scope

This skill is READ-ONLY and NO-LLM. It does NOT:
- Use any LLM or paid API provider
- Submit commands to Issue #45
- Create or modify PRs
- Edit any files
- Deploy to production
- Access PersianToolbox
- Access billing or schema

## Trigger

When user says: "status", "ASDEV status", "asdev status"

## Behavior

1. Read Issue #45 latest comments via GitHub API
2. Check open PRs in alirezasafaeisystems and auditsystems
3. Format structured status (no LLM summarization)
4. Post status to Telegram

## Commands to Execute (Read-Only, No LLM)

```bash
# Read Issue #45 latest comment
gh issue view 45 --repo alirezasafaei-dev/alirezasafaeisystems --json comments --jq '.comments[-1].body'

# Check open PRs (read-only)
gh pr list --repo alirezasafaei-dev/alirezasafaeisystems --state open --json number,title,updatedAt
gh pr list --repo alirezasafaei-dev/auditsystems --state open --json number,title,updatedAt
```

## Output Format (Structured, No LLM)

```
ASDEV Status — [timestamp]

Timer: active/inactive
Open PRs: [count]
Latest Issue #45: [first 200 chars of latest comment]
Blockers: [none/list]
```

## Safety

- Read-only: no file writes, no PR creation, no deploy
- No LLM: no paid API, no OpenAI, no model inference
- No secrets printed
- No PersianToolbox access
- No billing/payment access
- No command submission (Phase 1)
