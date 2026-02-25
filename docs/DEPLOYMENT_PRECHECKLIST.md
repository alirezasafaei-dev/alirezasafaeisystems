# Deployment Prechecklist

## Latest Verified Snapshot (2026-02-20)
- Active production release: `20260220T141000Z-hotfix5`
- Post-deploy validation: PASS (`/api/ready` edge = `200`)
- Production smoke checks from CI: PASS (PR #71)
- TLS/cert checks on edge: PASS
- Rollback/governance drills: prior evidence exists in `docs/runtime/`; no new rollback drill was required for this hotfix window

Evidence:
- `docs/runtime/` (deployment evidence snapshots)

## How to Use This Checklist
- Use this document as the template for the next release cycle.
- For each deployment window, copy this file into `docs/runtime/` with a date suffix and mark items.
- "Unchecked" items below are not currently broken; they are required re-validation gates for the next release.

## Before Deploy
- [ ] `pnpm run release:prepare:vps` passed and new runtime prep report exists in `docs/runtime/`.
- [ ] Co-hosting dependency order confirmed for this release window.
- [ ] `pnpm run verify` passed on the release commit.
- [ ] `pnpm run test:e2e:smoke` passed on the release commit.
- [ ] Production `.env` exists at `/var/www/my-portfolio/shared/env/production.env`.
- [ ] No placeholder secrets remain (`replace-with-*`).
- [ ] Server has required binaries: `node`, `pnpm`, `pm2`, `rsync`, `curl`.
- [ ] Target directories writable by deploy user.
- [ ] TLS termination path confirmed and certificate validity checked.
- [ ] Co-hosting topology validated: `bash scripts/deploy/check-hosting-sync.sh --strict`
- [ ] Unified nginx contract validated: `bash scripts/deploy/validate-cohosting-config.sh`

## Deploy
- [ ] Run `ops/deploy/deploy.sh --env production --source-dir <release-dir>`.
- [ ] Health check `GET /api/ready` returns `status: ready`.
- [ ] Home and admin-login pages load via production domain.

## After Deploy
- [ ] Check PM2 logs for runtime errors.
- [ ] Confirm Nginx upstream points to expected production process/port.
- [ ] Confirm cache/security headers on public and API routes.
- [ ] Confirm both domains are healthy after portfolio deploy:
- [ ] `https://persiantoolbox.ir` (no regression)
- [ ] `https://alirezasafaeisystems.ir` (portfolio healthy)

## Rollback (if needed)
- [ ] Run `ops/deploy/rollback.sh --env production`.
- [ ] Re-run health and smoke checks.
- [ ] Capture rollback reason and corrective action in release notes.
- [ ] Run formal rollback drill and store incident note:
  - `bash scripts/deploy/run-rollback-drill.sh --env production --site-url https://alirezasafaeisystems.ir`

## Release Governance
- [ ] Generate go/no-go evidence bundle:
  - `SITE_URL=https://alirezasafaeisystems.ir STAGING_URL=https://staging.alirezasafaeisystems.ir bash scripts/release/generate-go-no-go-evidence.sh`
- [ ] Confirm ownership matrix is filled:
  - `docs/ONCALL_ESCALATION.md`
- [ ] Validate ownership placeholders are fully replaced:
  - `bash scripts/release/validate-ownership.sh`

## بررسی‌های VPS
- اجرای `bash scripts/vps-preflight.sh --env production --strict`
- وجود فایل محیطی: `/var/www/my-portfolio/shared/env/production.env`
- دسترسی سرویس systemd و nginx
