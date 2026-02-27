# 10/10 Master Checklist

Target: make `alirezasafaeisystems` score 10/10 across engineering quality, operations reliability, documentation clarity, and conversion readiness.

Last updated: 2026-02-19
Owner: `platform-owner`

## Scoring Model
- `Engineering Quality` (25%)
- `Operations & Reliability` (25%)
- `Security & Governance` (20%)
- `Documentation & Maintainability` (15%)
- `Product & Conversion` (15%)

## A) Engineering Quality (25%)
- [x] `pnpm run verify` passes on release branch.
- [x] `pnpm run test:e2e:smoke` passes on release branch.
- [x] Lighthouse assertions pass locally for tracked routes.
- [x] Remove residual lint warnings (keep lint fully clean, no warnings).
- [x] Align all local/dev runtime environments with Node 20 policy.

Evidence:
- `.lighthouseci/assertion-results.json`

## B) Operations & Reliability (25%)
- [x] Production deploy validated with readiness and smoke checks.
- [x] Rollback drill executed and documented.
- [x] Onsite backup + restore drill evidence captured.
- [x] Offsite backup + restore drill evidence captured.
- [x] Add quarterly edge-header verification artifacts (`curl -I` for apex/www/staging).
- [x] Attach latest monthly incident/noise review note under runtime incidents.

Evidence:
- `docs/runtime/`

## C) Security & Governance (20%)
- [x] Branch protection + CODEOWNERS enforcement active.
- [x] Secret scanning and dependency high/critical gate active in CI.
- [x] Firewall/fail2ban verification evidence exists.
- [x] Fill remaining governance TODO metadata:
  - GitHub org 2FA enforcement state
- [x] Confirm secure storage process for 2FA recovery codes.

Evidence:
- `docs/runtime/`

## D) Documentation & Maintainability (15%)
- [x] Root-level `README.md` present and updated.
- [x] `docs/README.md` documentation index present.
- [x] Deployment roadmap and prechecklist aligned with latest runtime evidence.
- [x] Archive or mark superseded runtime/go-no-go files with placeholder owners.
- [x] Add monthly doc freshness review task in runtime evidence process.

## E) Product & Conversion (15%)
- [x] Finalize a single primary CTA.
- [x] Finalize service catalog (3-6 offers) with measurable deliverables.
- [x] Finalize pricing policy (public or form-only).
- [x] Finalize proof data for case studies (role, metrics, outcomes, tradeoffs).
- [x] Configure and confirm lead notification destination in production.
- [x] Finalize data retention policy for leads/messages.

Primary input source:
- Business owner inputs (CTA, offers, pricing, lead policy)

## Release Gate (10/10 Ready)
Mark release as 10/10 only when all below are true:
- [x] Section A has no open item.
- [x] Section B has no open item.
- [x] Section C has no open item.
- [x] Section D has no open item.
- [x] Section E has no open item.
- [x] Go/No-Go evidence regenerated with no placeholders.
