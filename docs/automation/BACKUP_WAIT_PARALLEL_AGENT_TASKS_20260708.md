# Backup-Wait Parallel Agent Tasks — 2026-07-08

Status: ready for agent execution after review/merge.

Purpose: keep ASDEV automation agents productive while the Phase 1 second encrypted backup runs on OWNER_PC. These tasks are intentionally repo-only, docs-only, or template-only. They must not touch backup execution, servers, deploy flow, or production.

## Global rules

- Use aliases only: OWNER_PC, IRAN_PROD, AUTOMATION_HOST, CRITICAL_SITE.
- Repo-only work unless a task explicitly says otherwise.
- No server access.
- No backup or restore execution.
- No deploy, install, build, service restart/reload, symlink switch, migration, firewall, or fail2ban work.
- No deletion.
- No sensitive material in logs, reports, commits, PR bodies, or comments.
- Do not modify active Phase 1 backup scripts while the second backup run is active.
- Open PRs only. Do not merge.

---

## ASDEV-BW01 — Repo safety audit and guardrails

Mode: docs-only / automation-script
Risk: low
Approval: auto
Validation: bash syntax check if a shell checker is created
Stop gates: suspected sensitive material, destructive command, server access
Done: PR open with docs and safe checker

Tasks:

1. Audit repo by path and metadata only.
2. Document local workspace safety rules.
3. Add or improve:
   - docs/ops/repo-safety-audit.md
   - docs/ops/secret-handling-policy.md
   - docs/ops/local-workspace-cleanup-policy.md
4. Add a safe checker if missing:
   - scripts/ops/check-repo-safety.sh
5. Checker requirements:
   - path-only scan by default
   - redacted reporting
   - non-zero exit for dangerous tracked files
   - no deletion or mutation
6. Open a PR titled:
   - docs(ops): add repo safety audit and secret guardrails

---

## ASDEV-BW02 — Phase 2 staging deploy prep, docs only

Mode: docs-only / automation-script
Risk: low
Approval: auto
Validation: bash syntax check if shell templates are created
Stop gates: real deploy command, server access, install/build/restart/reload/symlink/migration/firewall action
Done: PR open with Phase 2 docs and dry-run templates

Tasks:

1. Prepare Phase 2 staging deploy readiness docs.
2. Add or update:
   - docs/ops/phase-2-staging-deploy-runbook.md
   - docs/ops/phase-2-staging-preflight-checklist.md
   - docs/ops/phase-2-staging-rollback-checklist.md
   - docs/ops/phase-2-approval-gates.md
3. Add safe dry-run templates only if missing:
   - scripts/deploy/staging-preflight.sh
   - scripts/deploy/staging-healthcheck.sh
   - scripts/deploy/staging-rollback-dry-run.sh
4. Scripts must default to dry-run/check mode.
5. Add a hard blocker: Phase 2 cannot begin unless the latest Phase 1 CRITICAL_SITE snapshot is disaster-recovery ready.
6. Future approval phrase:
   - APPROVE_PHASE_2_STAGING_DEPLOY
7. Open a PR titled:
   - docs(deploy): prepare Phase 2 staging deploy runbook and dry-run checks

---

## ASDEV-BW03 — Monitoring and alerting prep only

Mode: docs-only / automation-script
Risk: low
Approval: auto
Validation: bash syntax check if shell templates are created
Stop gates: live timer enablement, server access, restart/reload, deploy, backup/restic mutation
Done: PR open with monitoring docs and safe templates

Tasks:

1. Prepare monitoring docs and template scripts only.
2. Add or update:
   - docs/ops/monitoring-runbook.md
   - docs/ops/backup-freshness-monitoring.md
   - docs/ops/critical-site-healthcheck.md
   - docs/ops/alerting-policy.md
3. Add safe templates:
   - scripts/monitoring/check-critical-site-http.sh
   - scripts/monitoring/check-backup-freshness.sh
   - scripts/monitoring/check-disk-local.sh
   - scripts/monitoring/notify-template.sh
4. Templates must use placeholders, default to dry-run/check mode, and enable nothing live.
5. Open a PR titled:
   - ops(monitoring): add safe monitoring and alerting templates

---

## Temporary execution priority

While the Phase 1 second backup is running, agents should execute only ASDEV-BW tasks and must not touch backup/runtime/deploy state.

Do not begin Phase 2 execution until the latest backup restore drill confirms CRITICAL_SITE disaster-recovery readiness.
