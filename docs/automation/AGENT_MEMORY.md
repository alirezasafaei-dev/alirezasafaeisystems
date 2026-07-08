# Agent Memory — ASDEV

**Format:** Each entry records agent state at a point in time.
**Source of Truth:** GitHub (alirezasafaei-dev/alirezasafaeisystems)

---

## Current State

**Date:** 2026-07-08
**Current Source of Truth:** GitHub
**Active PRs:** See [ACTIVE_AUTONOMOUS_QUEUE.md](ACTIVE_AUTONOMOUS_QUEUE.md)

---

## Decisions Made

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-06 | Hermes-first orchestration approved | n8n deferred; GitHub = command center |
| 2026-07-06 | Issue #45 as command bus | Single source for reports and commands |
| 2026-07-08 | Backup-wait phase active | Second backup may be running on OWNER_PC |

---

## Blockers

- No server access for backup-wait tasks
- No deploy/install/build/restart/reload/symlink/migration/firewall work during backup-wait
- PR #12 mega-branch needs splitting (A-Q01)

---

## Next Action

- Execute backup-wait safe tasks (ASDEV-BW01, ASDEV-BW02, ASDEV-BW03)
- Split PR #12 into focused PRs (A-Q01)

---

## Owner Approval Phrases

The following phrases indicate owner approval has been granted:

- "approved" / "go ahead" / "ship it"
- "merge it" / "do it" / "proceed"
- "deploy" / "push it" / "execute"
- Any explicit written approval in GitHub comments or Telegram

---

## What Must Not Be Repeated

- Do not re-read documents already in context after checkpoint rebuild
- Do not re-verify files that were just validated
- Do not re-run commands that just succeeded
- Do not ask about state that agent memory already records
- Do not create duplicate PRs for the same change
- Do not merge without owner review
- Do not deploy without owner approval

---

## Memory Updates

Agents append new entries at the bottom of this file when:
- A decision is made
- A blocker is discovered or resolved
- An approval is granted
- A task completes or fails
- The source of truth state changes

Format:

```
## [YYYY-MM-DD HH:MM UTC] Entry Title
- What happened
- Why it matters
- What's next
```
