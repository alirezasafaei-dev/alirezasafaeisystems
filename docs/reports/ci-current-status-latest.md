# CI Current Status — Latest

**Date:** 2026-07-08T21:15:00Z

## GitHub Actions

PR #72 workflows still fail in ~3–6s (infra-class). No rerun spam.

| Workflow | Class |
|----------|-------|
| CI Router | INFRA_FAIL (local equivalent PASS) |
| CI / Security / CodeQL / E2E / Lighthouse | INFRA_FAIL — non-blocking for deploy engine |

## Local

```bash
bash scripts/ops/run-ci-router-local.sh origin/main
# → CI ROUTER LOCAL: PASSED
```

## Classification

**INFRA_DEGRADED_NON_BLOCKING**
