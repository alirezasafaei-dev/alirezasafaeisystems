# ASDEV P0 Execution Order — 2026-07-12

## Current critical path

1. Mother self-hosted quality gate: PR #109, Issues #102/#105.
2. AuditSystems real main-gate execution on current main; do not accept configured/cancelled/no-step evidence.
3. Real-worker command bus and artifact-backed completion: Issue #98.
4. Current-main AuditSystems post-merge security and release review.
5. Production release preparation under #103; execution remains owner-gated.
6. Revenue sprint only after Production verification.

## Immediate decisions

- PR #107: close/reject; wrong base and no real worker.
- PR #104: close as superseded by self-hosted runner architecture.
- Issues #99/#100: original pre-merge targets are stale; close or re-scope to current-main post-merge evidence.
- Issue #94: resume only after #98 passes.
- AI Gateway rollout and reboot remain gated.

## Evidence standard

A successful claim requires exact SHA, real command/worker invocation, non-empty steps or artifact, exit code, validation result, and a durable link/path. Acknowledgement-only output is invalid.
