# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T19:30:00Z
**Status:** Active
**Source of Truth:** GitHub (alirezasafaei-dev/alirezasafaeisystems)

---

## Queue Rules

- Each task has: ID, Title, Repo, Mode, Risk, Approval, Validation, Stop Gates, Done Definition
- Valid modes: read-only, docs-only, test-only, product-branch, automation-script
- No combined modes (e.g., docs-only+automation-script is invalid)
- Risk: low, medium, high
- Approval: auto (no approval needed), owner (requires owner approval)
- Stop gates: conditions that halt execution

---

## Current Queue (Priority Order)

### 1. ASDEV-P71-CI
- **Title:** Stabilize PR #71 CI Router
- **Repo:** alirezasafaeisystems
- **Mode:** automation-script
- **Risk:** low
- **Approval:** auto
- **Validation:** CI Router passes or exact blocker reported
- **Stop Gates:** GitHub Actions infrastructure failure (not code issue)
- **Done Definition:** CI Router passes or root cause documented
- **Status:** IN PROGRESS — All CI workflows failing simultaneously (GitHub Actions infrastructure issue, not code issue)

### 2. ASDEV-AUTOHOST-READONLY
- **Title:** Read-only audit AUTOMATION_HOST
- **Repo:** alirezasafaeisystems
- **Mode:** read-only
- **Risk:** low
- **Approval:** owner (requires APPROVE_AUTOMATION_HOST_READONLY_AUDIT)
- **Validation:** Redacted host status report created
- **Stop Gates:** Any mutation attempt
- **Done Definition:** docs/reports/automation-host-readonly-audit-20260708.md created
- **Status:** BLOCKED — Waiting for owner approval

### 3. ASDEV-STAGING-PREP
- **Title:** Prepare CRITICAL_SITE staging execution
- **Repo:** alirezasafaeisystems
- **Mode:** docs-only
- **Risk:** low
- **Approval:** owner
- **Validation:** Exact staging command and rollback plan ready
- **Stop Gates:** Any deploy attempt
- **Done Definition:** docs/ops/staging-execution-plan.md created with exact commands
- **Status:** PENDING

### 4. ASDEV-CI-LEGACY-TRIAGE
- **Title:** Classify old failing workflows
- **Repo:** alirezasafaeisystems
- **Mode:** test-only
- **Risk:** low
- **Approval:** auto
- **Validation:** Legacy failures classified as blocker/non-blocker
- **Stop Gates:** None
- **Done Definition:** docs/reports/ci-legacy-failure-triage-20260708.md created
- **Status:** PENDING

---

## Archived Tasks

Old tasks moved to `docs/automation/QUEUE_ARCHIVE_20260708.md`:
- ASDEV-BW01 through ASDEV-BW03 (backup-wait directives)
- A-Q01 through A-Q20 (AuditSystems tasks)

---

## Queue Stats

| Metric | Value |
|---|---|
| Total tasks | 4 |
| Pending | 2 |
| In-progress | 1 |
| Completed | 0 |
| Blocked | 1 |
