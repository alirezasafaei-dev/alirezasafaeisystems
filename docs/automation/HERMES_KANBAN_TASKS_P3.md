# Hermes Kanban Tasks — Phase P3

**Date:** 2026-07-06
**Board:** asdev-audit
**Purpose:** Executable next tasks from heavy queue

---

## Created Tasks

| Task ID | Title | Assignee | Status |
|---|---|---|---|
| t_bf15bdb4 | JOB-H10: PersianToolbox Read-Only SEO Funnel Audit | hermes-asdev-reviewer | ready |
| t_fae7efde | JOB-H4: AuditSystems Report Scoring Consistency Audit | hermes-asdev-reviewer | ready |
| t_f6ea1dc7 | JOB-H5: AuditSystems Error-State UX Audit | hermes-asdev-reviewer | ready |
| t_998136b1 | JOB-H6: AuditSystems Analytics Event Consistency Audit | hermes-asdev-reviewer | ready |

---

## Task Details

### t_bf15bdb4 — PersianToolbox Read-Only SEO Funnel Audit

```yaml
repo_scope: [persiantoolbox]
mode: read-only
approval_required: false
protected_repos: [persiantoolbox]
validation: N/A (read-only)
report_target: issue:45
```

### t_fae7efde — AuditSystems Report Scoring Consistency Audit

```yaml
repo_scope: [auditsystems]
mode: read-only
approval_required: false
protected_repos: [persiantoolbox]
validation: N/A (read-only)
report_target: issue:45
```

### t_f6ea1dc7 — AuditSystems Error-State UX Audit

```yaml
repo_scope: [auditsystems]
mode: read-only
approval_required: false
protected_repos: [persiantoolbox]
validation: N/A (read-only)
report_target: issue:45
```

### t_998136b1 — AuditSystems Analytics Event Consistency Audit

```yaml
repo_scope: [auditsystems]
mode: read-only
approval_required: false
protected_repos: [persiantoolbox]
validation: N/A (read-only)
report_target: issue:45
```

---

## Dispatch

```bash
hermes kanban boards use asdev-audit
hermes kanban list
hermes kanban claim <task_id>
```

---

*Kanban tasks created. Ready for dispatch.*
