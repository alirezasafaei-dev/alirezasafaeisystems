# ASDEV Coordinated Production Release Runbook

**Owner:** ASDEV operations  
**Applies to:** coordinated AuditSystems and mother/portfolio production releases  
**Last reviewed:** 2026-07-16

This runbook defines the minimum safe path from frozen source SHAs to a verified production release. Product-specific commands remain in each product repository; this document owns coordination, authorization, evidence, and closure.

## Non-negotiable rules

1. Freeze full 40-character SHAs. Do not deploy a moving branch name.
2. Deploy one product at a time and wait for health checks before continuing.
3. Deploy AuditSystems before the mother site when both are in scope.
4. Back up and rehearse every database-affecting release.
5. Keep credentials and environment files on the server; never paste them into GitHub, logs, or reports.
6. A production deployment requires an explicit owner token for the exact SHAs and UTC window.
7. If the deployed SHA, runtime port, PM2 name, or current symlink differs from the approved plan, stop and reconcile the drift.
8. Preserve the previous known-good release until the observation window has ended.

## 1. Freeze the release

Record:

```text
RELEASE_ID=<number>
AUDIT_RELEASE_SHA=<40-char-sha>
MOTHER_RELEASE_SHA=<40-char-sha>
WINDOW_UTC=<start/end>
ROLLBACK_TARGET_AUDIT=<release-id-or-sha>
ROLLBACK_TARGET_MOTHER=<release-id-or-sha>
```

Verify that each SHA is reachable from the intended repository and that all required remediation PRs are merged. Later automation-only commits do not alter the frozen release identity.

## 2. Run release gates

### Mother / portfolio

From the mother repository:

```bash
pnpm install --frozen-lockfile
pnpm run type-check
pnpm run lint
pnpm run test
pnpm run build
```

Use the exact script names present at the frozen SHA if package scripts differ.

### AuditSystems

From the AuditSystems repository:

```bash
pnpm install --frozen-lockfile
pnpm run scan:secrets
pnpm run check:actions-pinned
pnpm run check
pnpm run deploy:readiness
```

If migrations, schema, backup/restore, or database-dependent code changed, perform a PostgreSQL rehearsal against disposable databases. The rehearsal must prove clean migration, idempotence, backup integrity, restore, key table presence, and source database immutability.

## 3. Prepare rollback

Before production mutation:

- identify the previous known-good immutable release for each product;
- verify that its source and runtime configuration still exist;
- create and verify the AuditSystems database backup using the product runbook;
- record the backup path and SHA-256 in protected operational evidence, not in public logs if the path is sensitive;
- confirm the operator is authorized to execute rollback;
- confirm that environment files and secrets are not included in release artifacts.

A backup is not considered valid until its gzip/dump integrity check passes.

## 4. Obtain owner authorization

The owner must provide a new token using the exact release SHAs:

```text
APPROVED_PRODUCTION_RELEASE_<release> audit=<full-sha> mother=<full-sha> window=<UTC> rollback=AUTHORIZED
```

Reject authorization when:

- either SHA is abbreviated or different from the frozen release;
- the UTC window is missing or expired;
- rollback is not explicitly authorized;
- the deployment scope changed after approval.

## 5. Deploy

### AuditSystems first

Use the deployment entrypoint documented at the frozen AuditSystems SHA. The repository-level wrapper is:

```bash
bash scripts/vps-deploy.sh deploy production
```

The lower-level immutable release script is:

```bash
bash ops/deploy/deploy.sh \
  --env production \
  --source-dir /path/to/extracted-release \
  --release-id <release-id>
```

Do not assume the repository script's default port or PM2 name matches the current VPS registry. Confirm the effective production port, PM2 process names, Nginx upstream, and current symlink before and after activation.

Wait for AuditSystems readiness and worker stability before proceeding.

### Mother / portfolio second

Use the mother repository wrapper:

```bash
bash scripts/vps-deploy.sh deploy production
```

Wait for local readiness and the public HTTPS check before continuing.

## 6. Verify production

### AuditSystems

```bash
curl -fsS https://audit.alirezasafaeisystems.ir/api/ready
curl -fsS https://audit.alirezasafaeisystems.ir/api/health
bash scripts/smoke-public-routes.sh https://audit.alirezasafaeisystems.ir
```

Also verify:

- readiness reports database and Redis as healthy;
- both the web and worker PM2 processes are online and stable;
- the active symlink points to the expected release ID;
- the deployed source or build metadata matches `AUDIT_RELEASE_SHA`;
- the queue is not showing abnormal backlog growth;
- no secret appears in output or stored evidence.

### Mother / portfolio

```bash
curl -fsS https://alirezasafaeisystems.ir/
curl -fsS https://alirezasafaeisystems.ir/api/ready
```

Also verify the PM2 process, current symlink, deployed SHA/build metadata, and Nginx upstream.

## 7. Roll back when necessary

Rollback is required when any of the following persists after the normal startup allowance:

- readiness fails;
- database or Redis is unavailable;
- sustained 5xx errors appear;
- worker crashes or queue growth is abnormal;
- the active artifact does not match the approved SHA;
- a critical authentication, billing, report, CSRF, or data-integrity regression is confirmed.

Rollback AuditSystems using its [product rollback runbook](https://github.com/alirezasafaei-dev/auditsystems/blob/main/docs/ROLLBACK_RUNBOOK.md). Roll back the mother site using its repository rollback entrypoint. If a migration or data-integrity incident is involved, stop application writes and follow the database recovery plan; do not improvise a down migration in production.

## 8. Close the release

Record one terminal report containing:

- deployment timestamp in UTC;
- exact source SHAs and immutable release IDs;
- PM2 process names and effective host ports;
- active symlink targets;
- readiness, health, and public smoke results;
- backup verification and rollback target;
- production mutation status;
- accepted risks and their expiry;
- links to evidence PRs/issues;
- final verdict: `DEPLOYED`, `ROLLED_BACK`, or `BLOCKED`.

For the completed example, see [Release #103 Production Closure](RELEASE_103_PRODUCTION_CLOSURE.md).
