# ASDEV Heavy Job Queue

**Status:** Active (2026-07-06)
**Purpose:** Backlog of autonomous jobs supporting ASDEV Audit

---

## Job Queue

### JOB-H1: AuditSystems CTA Registry Closure

```yaml
id: JOB-H1
title: AuditSystems CTA Registry Closure
goal: Ensure all CTAs use the registry, no ad-hoc links remain
repo_scope: [auditsystems]
allowed_agent: hermes-asdev-code-draft
mode: code-implementation
autonomy: draft-only
risk: medium
approval_required: true
validation: pnpm typecheck && pnpm lint && pnpm test && pnpm build
rollback: git revert
done_definition: All CTAs registry-backed, no direct href CTAs
```

### JOB-H2: AuditSystems Sample Report Trust Upgrade

```yaml
id: JOB-H2
title: AuditSystems Sample Report Trust Upgrade
goal: Improve trust signals in sample report page
repo_scope: [auditsystems]
allowed_agent: hermes-asdev-code-draft
mode: code-implementation
autonomy: draft-only
risk: medium
approval_required: true
validation: pnpm typecheck && pnpm lint && pnpm test && pnpm build
rollback: git revert
done_definition: Trust labels, disclaimers, evidence links verified
```

### JOB-H3: AuditSystems Public Route Smoke Test Suite

```yaml
id: JOB-H3
title: AuditSystems Public Route Smoke Test Suite
goal: Add smoke tests for all public routes
repo_scope: [auditsystems]
allowed_agent: hermes-asdev-code-draft
mode: code-implementation
autonomy: draft-only
risk: low
approval_required: true
validation: pnpm test
rollback: git revert
done_definition: Smoke tests pass for /audit, /sample-report, /pricing, /signup
```

### JOB-H4: AuditSystems Report Scoring Consistency Audit

```yaml
id: JOB-H4
title: AuditSystems Report Scoring Consistency Audit
goal: Verify scoring logic is consistent across report types
repo_scope: [auditsystems]
allowed_agent: hermes-asdev-reviewer
mode: read-only-review
autonomy: read-only
risk: low
approval_required: false
validation: N/A (read-only)
rollback: N/A
done_definition: Audit report produced, gaps documented
```

### JOB-H5: AuditSystems Error-State and Retry UX Audit

```yaml
id: JOB-H5
title: AuditSystems Error-State and Retry UX Audit
goal: Audit error states and retry UX across the app
repo_scope: [auditsystems]
allowed_agent: hermes-asdev-reviewer
mode: read-only-review
autonomy: read-only
risk: low
approval_required: false
validation: N/A (read-only)
rollback: N/A
done_definition: Error-state audit report produced
```

### JOB-H6: AuditSystems Analytics Event Consistency Audit

```yaml
id: JOB-H6
title: AuditSystems Analytics Event Consistency Audit
goal: Verify analytics events are consistent and complete
repo_scope: [auditsystems]
allowed_agent: hermes-asdev-reviewer
mode: read-only-review
autonomy: read-only
risk: low
approval_required: false
validation: N/A (read-only)
rollback: N/A
done_definition: Analytics audit report produced
```

### JOB-H7: ASDEV Portfolio Case-Study Conversion Path

```yaml
id: JOB-H7
title: ASDEV Portfolio Case-Study Conversion Path
goal: Add conversion paths from case studies to audit CTA
repo_scope: [alirezasafaeisystems]
allowed_agent: hermes-asdev-code-draft
mode: code-implementation
autonomy: draft-only
risk: low
approval_required: true
validation: pnpm type-check && pnpm lint && pnpm test && pnpm build
rollback: git revert
done_definition: Case studies link to audit CTA, conversion tracked
```

### JOB-H8: ASDEV Qualification Page Improvement

```yaml
id: JOB-H8
title: ASDEV Qualification Page Improvement
goal: Improve qualification page UX and conversion
repo_scope: [alirezasafaeisystems]
allowed_agent: hermes-asdev-code-draft
mode: code-implementation
autonomy: draft-only
risk: low
approval_required: true
validation: pnpm type-check && pnpm lint && pnpm test && pnpm build
rollback: git revert
done_definition: Qualification page improved, conversion tested
```

### JOB-H9: ASDEV Pricing/Copy Consistency Review

```yaml
id: JOB-H9
title: ASDEV Pricing/Copy Consistency Review
goal: Review pricing page copy for consistency and trust
repo_scope: [alirezasafaeisystems]
allowed_agent: hermes-asdev-reviewer
mode: read-only-review
autonomy: read-only
risk: low
approval_required: false
validation: N/A (read-only)
rollback: N/A
done_definition: Pricing review report produced
```

### JOB-H10: PersianToolbox Read-Only SEO Funnel Audit

```yaml
id: JOB-H10
title: PersianToolbox Read-Only SEO Funnel Audit
goal: Audit SEO funnel from PersianToolbox to ASDEV Audit
repo_scope: [persiantoolbox]
allowed_agent: hermes-asdev-reviewer
mode: read-only-review
autonomy: read-only
risk: low
approval_required: false
validation: N/A (read-only)
rollback: N/A
done_definition: SEO funnel audit report produced
```

### JOB-H11: PersianToolbox Protected CTA Proposal Only

```yaml
id: JOB-H11
title: PersianToolbox Protected CTA Proposal Only
goal: Propose CTA improvements (no implementation)
repo_scope: [persiantoolbox]
allowed_agent: hermes-asdev-docs
mode: docs-only
autonomy: docs-only
risk: low
approval_required: false
validation: N/A (docs-only)
rollback: N/A
done_definition: CTA proposal document produced
```

### JOB-H12: DevAtlas Future-Module Boundary Doc

```yaml
id: JOB-H12
title: DevAtlas Future-Module Boundary Doc
goal: Document DevAtlas boundaries for future development
repo_scope: [alirezasafaeisystems]
allowed_agent: hermes-asdev-docs
mode: docs-only
autonomy: docs-only
risk: low
approval_required: false
validation: N/A (docs-only)
rollback: N/A
done_definition: DevAtlas boundary document produced
```

### JOB-H13: Automation Command Loop Reliability Hardening

```yaml
id: JOB-H13
title: Automation Command Loop Reliability Hardening
goal: Harden command loop scripts for reliability
repo_scope: [alirezasafaeisystems]
allowed_agent: hermes-asdev-ops
mode: code-implementation
autonomy: local-only
risk: low
approval_required: false
validation: bash -n scripts/agent-command-center/*.sh
rollback: git revert
done_definition: Scripts hardened, dry-run passes
```

### JOB-H14: Provider Fallback Policy

```yaml
id: JOB-H14
title: Provider Fallback Policy
goal: Document provider fallback strategy
repo_scope: [alirezasafaeisystems]
allowed_agent: hermes-asdev-docs
mode: docs-only
autonomy: docs-only
risk: low
approval_required: false
validation: N/A (docs-only)
rollback: N/A
done_definition: Provider fallback policy document produced
```

### JOB-H15: Telegram Approval Gateway Dry-Run

```yaml
id: JOB-H15
title: Telegram Approval Gateway Dry-Run
goal: Test Telegram approval flow in dry-run mode
repo_scope: [alirezasafaeisystems]
allowed_agent: hermes-asdev-ops
mode: dry-run
autonomy: local-only
risk: low
approval_required: false
validation: N/A (dry-run)
rollback: N/A
done_definition: Telegram approval dry-run documented
```

### JOB-H16: OpenCode Worker Benchmark

```yaml
id: JOB-H16
title: OpenCode Worker Benchmark
goal: Benchmark OpenCode for ASDEV tasks
repo_scope: [alirezasafaeisystems]
allowed_agent: hermes-asdev-ops
mode: dry-run
autonomy: local-only
risk: low
approval_required: false
validation: N/A (benchmark)
rollback: N/A
done_definition: OpenCode benchmark report produced
```

---

## Execution Order

| Priority | Job | Agent | Mode |
|---|---|---|---|
| 1 | JOB-H13 | hermes-asdev-ops | local-only |
| 2 | JOB-H10 | hermes-asdev-reviewer | read-only |
| 3 | JOB-H4 | hermes-asdev-reviewer | read-only |
| 4 | JOB-H5 | hermes-asdev-reviewer | read-only |
| 5 | JOB-H6 | hermes-asdev-reviewer | read-only |
| 6 | JOB-H7 | hermes-asdev-code-draft | draft |
| 7 | JOB-H8 | hermes-asdev-code-draft | draft |
| 8 | JOB-H9 | hermes-asdev-reviewer | read-only |
| 9 | JOB-H11 | hermes-asdev-docs | docs-only |
| 10 | JOB-H12 | hermes-asdev-docs | docs-only |
| 11 | JOB-H14 | hermes-asdev-docs | docs-only |
| 12 | JOB-H15 | hermes-asdev-ops | dry-run |
| 13 | JOB-H16 | hermes-asdev-ops | dry-run |

---

## Protected Rules

- PersianToolbox jobs: read-only or proposal-only
- No auto-deploy
- No auto-push to main
- No billing changes
- No force push
- No secret exposure

---

*Queue created. 16 jobs defined. Safe for autonomous execution.*
