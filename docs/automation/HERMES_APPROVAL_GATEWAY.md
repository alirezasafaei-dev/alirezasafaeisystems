# Hermes Approval Gateway — Design

**Status:** Design only (not deployed)
**Date:** 2026-07-06
**Purpose:** Owner approval/deny via Telegram or email

---

## Current State

| Channel | Configured | Health |
|---|---|---|
| Telegram | ✅ Yes | ⚠️ Connection failing (network) |
| Email | ✅ Yes | Not tested |
| GitHub PR comments | ✅ Yes | Working |

---

## Approval Flow

```text
Agent creates task or requests approval
  → Hermes sends approval request via Telegram/Email
  → Owner responds: Approved / Denied / Emergency Stop
  → Hermes updates task status
  → Agent continues or halts
```

---

## Approval Phrases

### Standard Approvals

```
Approved: automation-only merge
Approved: auditsystems feature branch only
Approved: push {branch_name}
Approved: merge PR #{number}
```

### PersianToolbox Special Approval

```
Approved (special): persiantoolbox — {exact scope}
```

### Denials

```
Denied: {reason}
Denied: PersianToolbox changes not approved
Denied: production deploy not approved
```

### Emergency

```
Emergency stop: freeze all agents
Emergency stop: halt automation
```

### Request Changes

```
Request changes: {description}
```

---

## Deny Rules (Hermes Safety)

```yaml
approvals:
  deny:
    - "git push --force*"
    - "rm -rf *"
    - "sudo rm*"
    - "mkfs*"
    - "dd if=*"
    - "*curl*|*sh*"
    - "*wget*|*sh*"
    - "vercel deploy --prod*"
    - "railway up*"
    - "docker compose down -v*"
    - "gh repo delete*"
```

---

## Implementation Notes

### Telegram Gateway

- Hermes gateway service is running
- Telegram bot configured but connection failing (network issue)
- When connection restores, approval requests will work
- `/approve` and `/deny` commands available in gateway

### Email

- Configured but not tested
- Can send approval requests via SMTP
- Owner replies to approve/deny

### GitHub PR Comments (Fallback)

- Always works
- Owner comments `Approved: ...` on PR #42
- Agent reads via `gh pr view`

---

## Dry-Run Test

```bash
# Test approval request (Telegram)
hermes send "Test approval request: Approved: dry-run test?"

# Test without sending real message
# Just document the flow
```

---

## Files

| File | Purpose |
|---|---|
| `docs/automation/HERMES_APPROVAL_GATEWAY.md` | This file |
| `docs/automation/HERMES_APPROVAL_GATES.md` | Existing gate tiers |

---

*Approval gateway design complete. Not deployed — Telegram connection issue.*
