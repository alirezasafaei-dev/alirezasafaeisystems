# alirezasafaeisystems.ir — GitHub Main Release Runbook

**Scope:** the Next.js application deployed at `https://alirezasafaeisystems.ir` from this repository.  
**Source of truth:** `alirezasafaei-dev/alirezasafaeisystems` → `main`.  
**Production workflow:** `.github/workflows/deploy-vps.yml` (`Deploy VPS`).

> This runbook is site-specific. Historical `CRITICAL_SITE` documents that name `persiantoolbox.ir` describe a different site/runtime and MUST NOT be used as production evidence for `alirezasafaeisystems.ir`.

## Release invariant

A production release is accepted only when the same exact Git commit SHA can be followed through all of these stages:

1. reviewed PR head and hosted quality gates;
2. merge commit on `main`;
3. `Deploy VPS` workflow target ref;
4. remote deployment and post-deploy smoke;
5. two-pass live browser verification;
6. commit statuses `production/deploy=success` and `production/live-verification=success`.

Do not substitute a branch name, a nearby commit, a different domain, or narrative-only evidence for the exact SHA chain.

## Pre-merge gate

For a release PR, record the current PR head SHA immediately before merge and require the repository's hosted PR checks to be successful on that head/merge candidate:

- CI Router
- Security Audit
- CodeQL
- E2E Smoke
- CI
- Lighthouse Budget

If the PR head moves, stale check results do not authorize the new head. Re-read the checks for the new SHA.

Merge with the expected head SHA so GitHub rejects the merge if the branch changes between verification and integration.

## What automatically deploys

`Deploy VPS` runs on pushes to `main` when the push changes a configured runtime/deployment path, currently including:

- `src/**`
- `ops/**`
- `prisma/**`
- `public/**`
- package/lock/config files listed in the workflow
- `.github/workflows/deploy-vps.yml`
- `scripts/deploy/**`
- `scripts/vps-preflight.sh`
- `scripts/verify.sh`

Docs-only, test-only, and other paths outside that list do not by themselves constitute a production application deployment. Always confirm whether a `Deploy VPS` run actually exists for the merge SHA instead of inferring it.

## Production target

For normal `main` push releases, the workflow targets production and uses:

- application base directory: `/var/www/my-portfolio`
- persistent SQLite: `/var/www/my-portfolio/shared/data/production.db`
- internal production port: `3002`
- public base URL: `https://alirezasafaeisystems.ir`

The workflow reaches the target through the configured SSH jump/target secrets. Secret values are never release evidence and must never be copied into reports.

## Workflow evidence sequence

### 1. Quality gate

The workflow checks out the exact target ref and runs the repository verification command. A failed quality gate blocks remote deployment.

### 2. Source preparation and persistence guard

The workflow uploads the release source to a unique temporary directory. For production it runs the legacy-SQLite relocation guard before activation so the persistent production database is not silently replaced by release-local state.

### 3. Remote deploy

The workflow executes `ops/deploy/deploy.sh` for the exact target ref/release id and retains rollback releases according to the deployment policy.

### 4. Post-deploy smoke

Production acceptance includes checks against internal port `3002` and the public site, including at least:

- `/api/ready`
- `/`
- `/services`
- `/discover`
- `/en/discover`
- `/profile`

The readiness GET/HEAD contract must agree and the readiness payload must report ready.

### 5. Live browser verification

The workflow runs `scripts/deploy/live-verify.mjs` twice against the public production base URL and uploads the resulting evidence artifacts. A release is not considered live-verified from a single narrative claim.

### 6. Exact commit statuses

For a successful production release, verify on the merge SHA:

- `production/deploy = success`
- `production/live-verification = success`

These statuses are the final machine-readable link between the source commit and production acceptance.

## Rollback discipline

If production verification fails, do not paper over the failed SHA with a later unrelated release. Preserve the failed run evidence, use the repository's governed rollback mechanism/release history, and verify the rollback target with the same readiness/public checks.

Never delete rollback releases as part of ordinary acceptance cleanup.

## Reference release — 2026-08-21

PR #197 demonstrates the current evidence chain:

- verified PR head: `cd0e3e857d4378a09b8583e0a53c4c4c8518fab6`
- merge commit: `8bb9ed88efd941f5007daa9e6b17d0ede2326f62`
- `Deploy VPS` run: `32472182024`
- quality gate: success
- source preparation / SQLite relocation: success
- remote deploy: success
- post-deploy smoke: success
- live browser verification: success
- merge-SHA statuses: `production/deploy=success`, `production/live-verification=success`

This example is evidence for `alirezasafaeisystems.ir` only. It must not be reused as proof for another domain.

## Release record template

Record at minimum:

```text
PR: #<number>
Verified PR head: <sha>
Merge SHA: <sha>
Deploy VPS run: <run-id or NOT_TRIGGERED_BY_PATH_FILTER>
Target: production | no-runtime-deploy
Quality gates: <exact conclusions>
Remote deploy: <success/failure/not-triggered>
Post-deploy smoke: <success/failure/not-triggered>
Live browser verification: <success/failure/not-triggered>
production/deploy: <success/failure/not-applicable>
production/live-verification: <success/failure/not-applicable>
Residual warnings: <explicit list or none>
```
