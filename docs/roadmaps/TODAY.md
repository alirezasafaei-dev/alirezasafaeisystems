# TODAY — ASDEV Immediate Priorities

**Date:** 2026-07-08
**Source of Truth:** GitHub

---

## PR Review/Merge Order

| Priority | Task | Repo | Status | Action |
|---|---|---|---|---|
| 1 | ASDEV-BW01: Repo safety audit | alirezasafaeisystems | Pending | Create PR with docs and safe checker |
| 2 | ASDEV-BW02: Phase 2 staging deploy prep | alirezasafaeisystems | Pending | Create PR with Phase 2 docs |
| 3 | ASDEV-BW03: Monitoring prep | alirezasafaeisystems | Pending | Create PR with monitoring docs |
| 4 | A-Q01: Split PR #12 | auditsystems | Pending | Break mega-branch into focused PRs |

---

## Blocked Items

| Item | Blocker | Resolution |
|---|---|---|
| A-Q05: deploy workflow quarantine | Requires owner approval | Wait for owner review |
| A-Q06: schema features quarantine | Requires owner approval | Wait for owner review |
| Backup-wait tasks | Second backup may be running | Complete backup drill, then proceed |
| Deploy to IRAN_PROD | No owner approval | Request owner approval |

---

## Exact Next Actions

1. **Execute ASDEV-BW01** — repo safety audit and guardrails
   - Create docs and safe checker script
   - Open PR for review
   - No server access, no destructive operations

2. **Execute ASDEV-BW02** — Phase 2 staging deploy prep
   - Create documentation and dry-run templates
   - Open PR for review
   - No real deploy, no server access

3. **Execute ASDEV-BW03** — monitoring and alerting prep
   - Create monitoring docs and safe templates
   - Open PR for review
   - No live timers, no server access

4. **Update AGENT_MEMORY.md** — record today's decisions and state
5. **Post status to Issue #45** — command center visibility

---

## Validation Commands

```bash
# Before any PR
pnpm lint
pnpm type-check
pnpm test
pnpm build
```

---

## Stop Conditions

- If any backup-wait blocker is triggered, halt and report
- If owner approval is required, do not proceed without it
- If validation fails, fix before proceeding
