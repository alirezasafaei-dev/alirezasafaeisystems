# Immediate Execution List

Updated: 2026-02-27

## Phase P0 (Done)
- [x] Local cleanup/refactor and dependency alignment completed.
- [x] Local quality gates refreshed with real evidence:
  - `pnpm type-check`
  - `pnpm test` (`164` tests)
  - `pnpm run build`
  - `pnpm run test:e2e:smoke` (`8` smoke checks)

## Phase P1 (Done)
- [x] VPS access and runtime health checks completed.
- [x] Edge-header verification evidence refreshed from trusted VPS network.
- [x] Governance non-local blockers closed (org 2FA + recovery-code process).

## Phase P2 (Done)
- [x] Primary CTA finalized.
- [x] Service catalog finalized.
- [x] Pricing policy finalized.
- [x] Lead destination finalized.
- [x] Data retention policy finalized.

## Current Command Set
```bash
pnpm type-check
pnpm test
pnpm run build
pnpm run test:e2e:smoke
pnpm run codex:report
```

## Status
- all previously open local and non-local blockers are closed.
- runtime evidence updated to 2026-02-27 (`ENTERPRISE_RUNTIME_STATUS`, `CODEX_CLI_AUTOCOMPACT_STATUS_LATEST`, heartbeat).
