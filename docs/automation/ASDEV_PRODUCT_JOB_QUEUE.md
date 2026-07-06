# ASDEV Product Job Queue

**Date:** 2026-07-06
**Purpose:** Next product jobs for ASDEV Audit

---

## Queue

### JOB-P1: Audit Result Persistence Strategy

```yaml
id: JOB-P1
title: Audit Result Persistence Strategy
repo: auditsystems
goal: Better report reliability and history
risk: medium
approval_required: true
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Audit results persisted and retrievable
```

### JOB-P2: Audit History Page

```yaml
id: JOB-P2
title: Audit History Page
repo: auditsystems
goal: More submitted audits via repeat usage
risk: low
approval_required: true
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Users can view past audit runs
```

### JOB-P3: Report Export/Share Flow

```yaml
id: JOB-P3
title: Report Export/Share Flow
repo: auditsystems
goal: More leads via sharing
risk: low
approval_required: true
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Reports exportable as PDF/shareable via link
```

### JOB-P4: Agency Lead Form

```yaml
id: JOB-P4
title: Agency Lead Form
repo: auditsystems
goal: More agency contacts
risk: low
approval_required: true
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Agency inquiry form functional
```

### JOB-P5: Pricing Conversion Experiment

```yaml
id: JOB-P5
title: Pricing Conversion Experiment
repo: auditsystems
goal: Higher paid user conversion
risk: medium
approval_required: true
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Pricing page A/B test ready
```

### JOB-P6: Failure Diagnostics Improvement

```yaml
id: JOB-P6
title: Failure Diagnostics Improvement
repo: auditsystems
goal: Lower support cost
risk: low
approval_required: false
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Better error messages and diagnostics
```

### JOB-P7: Report Scoring Engine Formalization

```yaml
id: JOB-P7
title: Report Scoring Engine Formalization
repo: auditsystems
goal: Better trusted audit reports
risk: medium
approval_required: true
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Scoring formula documented and tested
```

### JOB-P8: Performance Budget Checks

```yaml
id: JOB-P8
title: Performance Budget Checks
repo: auditsystems
goal: Better audit report quality
risk: low
approval_required: false
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Performance budgets included in reports
```

### JOB-P9: Security Finding Evidence Display

```yaml
id: JOB-P9
title: Security Finding Evidence Display
repo: auditsystems
goal: Better trusted audit reports
risk: low
approval_required: false
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Security findings show evidence
```

### JOB-P10: Audit Readiness Checklist Integration

```yaml
id: JOB-P10
title: Audit Readiness Checklist Integration
repo: auditsystems
goal: More submitted audits
risk: low
approval_required: false
validation: pnpm typecheck && pnpm lint && pnpm test
rollback: git revert
done_definition: Audit readiness page linked from audit form
```

---

## Priority Order

| Priority | Job | Goal |
|---|---|---|
| 1 | JOB-P6 | Failure diagnostics |
| 2 | JOB-P10 | Audit readiness integration |
| 3 | JOB-P8 | Performance budgets |
| 4 | JOB-P9 | Security evidence |
| 5 | JOB-P2 | Audit history |
| 6 | JOB-P3 | Report export |
| 7 | JOB-P4 | Agency lead form |
| 8 | JOB-P7 | Scoring engine |
| 9 | JOB-P1 | Result persistence |
| 10 | JOB-P5 | Pricing experiment |

---

*Queue created. Ready for next sprint.*
