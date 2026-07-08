# ASDEV Deployment Standard

**Version:** 1.1
**Last Updated:** 2026-07-08
**Scope:** All production site deployments

### Runtime port isolation (v1.1)

- Registry must define distinct `prod_port` and `staging_port` (never equal).
- CRITICAL_SITE defaults: production **3100**, staging **3200**.
- Deploy engine resolves port per environment; refuses target port if in use by non-owned process.
- See `docs/ops/runtime-port-isolation.md`.

---

## 1. Overview

This document defines the standard deployment process for all ASDEV sites. All deployments must follow this standard to ensure consistency, safety, and auditability.

---

## 2. Deployment Pipeline

### 2.1 Pre-deployment Phase
1. **Preflight Checks** (`asdev-preflight.sh`)
   - Validate site exists in registry
   - Check deploy path accessibility
   - Check shared path exists
   - Check for conflicting deployments
   - Validate environment tools

2. **Change Detection** (built into deploy script)
   - Compare current and new versions via git diff
   - Classify changes: docs, source, config, deps, other
   - Generate change manifest

### 2.2 Deployment Phase
1. **Deployment Execution** (`asdev-deploy.sh`)
   - Sync site-scoped source or artifact to release directory
   - Run build command ID from registry
   - Switch `current` symlink to new release (post-activation)
   - Run healthcheck AFTER symlink switch (post-activation)
   - Roll back symlink to previous release if healthcheck fails
   - Record deployment metadata

2. **Health Verification** (`asdev-healthcheck.sh`)
   - Verify current symlink is valid
   - Check process names are running
   - Verify HTTP health endpoint responds 2xx/3xx

### 2.3 Post-deployment Phase
1. **Rollback Readiness** (`asdev-rollback.sh`)
   - Swap current symlink to previous known-good release
   - Run healthcheck after symlink swap
   - No file copying — symlink-only rollback

2. **Release Cleanup** (`asdev-release-gc.sh`)
   - Quarantine excess releases (never delete by default)
   - Deletion requires explicit APPROVE_RELEASE_DELETE
   - Protected sites: releases are never deleted

---

## 3. Change Detection Rules

### 3.1 Change Categories
- **docs**: Documentation files (*.md, *.txt)
- **assets**: Static assets (images, fonts, CSS, JS)
- **deps**: Dependency changes (package.json, requirements.txt)
- **source**: Source code changes (*.ts, *.js, *.py)
- **config**: Configuration changes (*.env, *.json, *.yaml)
- **migration**: Database migrations or schema changes

### 3.2 Change Impact Assessment
| Category | Impact Level | Required Approval |
|----------|--------------|-------------------|
| docs | Low | Standard |
| assets | Low | Standard |
| deps | Medium | Standard |
| source | High | Standard |
| config | High | Standard |
| migration | Critical | CRITICAL_SITE approval |

---

## 4. Approval Gates

### 4.1 Staging Deployment
- **Approval Phrase:** `APPROVE_PHASE_2_STAGING_DEPLOY`
- Required for all staging deploys via `--approve-phrase`
- Without approval phrase, script defaults to dry-run mode

### 4.2 Production Deployment
- **Approval Phrase:** `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`
- Required for all production deploys via `--approve-phrase`
- Protected sites (persiantoolbox.ir) require this for any production change
- Without approval phrase, script defaults to dry-run mode

### 4.3 Release Garbage Collection
- **Approval Phrase:** `APPROVE_RELEASE_DELETE`
- Required for deleting quarantined releases
- Without this phrase, GC only quarantines — never deletes
- Protected site quarantined releases are never deleted

---

## 5. Deployment Metadata

Every deployment must record:
- Timestamp
- Site name
- Deployer identity
- Change manifest
- Backup location
- Health check results
- Approval status (if required)

---

## 6. Rollback Procedures

### 6.1 Rollback Mechanism
- Rollback swaps the current symlink to a previous release directory
- No file copying — purely symlink-based
- Healthcheck runs after symlink swap to verify rollback succeeded

### 6.2 Manual Rollback
- Use `asdev-rollback.sh --site <name> --environment <env> --commit <sha>`
- Specify `--target-version` for explicit rollback target
- Approval required per environment (staging/production phrases)
- Records rollback event in deployment log

---

## 7. Release Garbage Collection

### 7.1 Quarantine Process
- Excess releases beyond `--keep-releases` are moved to `.quarantine/`
- Releases older than `--quarantine-days` are candidates for quarantine
- Quarantine is the ONLY default action — no deletion without explicit approval

### 7.2 Deletion Rules
- Deletion requires `--approve-phrase APPROVE_RELEASE_DELETE`
- Protected sites: quarantined releases are NEVER deleted
- Without approval phrase, aged quarantined releases are logged but not deleted

---

## 8. Monitoring and Alerts

### 8.1 Health Checks
- Run after every deployment
- Check HTTP endpoints
- Verify static asset availability
- Validate application responses

### 8.2 Healthcheck Model (Post-Activation)
The deploy script uses a **post-activation healthcheck** model:
1. Build and prepare the release directory
2. Switch `current` symlink to the new release (activation)
3. Run healthcheck against the live endpoint
4. If healthcheck fails → automatically roll back the symlink to the previous known-good release
5. If no previous release exists → warn and leave symlink pointing to failed release

This ensures the healthcheck validates the actual production traffic path, not just the build artifact.

### 8.3 Failure Handling
- Deploy script rolls back `current` symlink to previous release if post-activation healthcheck fails
- Manual rollback available via `asdev-rollback.sh`
- Log failure details for investigation

---

## 9. Compliance

### 9.1 Audit Trail
- All deployments are logged
- Metadata is preserved
- Rollback events are recorded

### 9.2 Security
- No secrets in deployment logs
- Environment variables used for configuration
- Secure backup storage

---

## 10. Tooling

### 10.1 Available Scripts
- `asdev-deploy.sh` - Main deployment script
- `asdev-preflight.sh` - Pre-deployment checks
- `asdev-healthcheck.sh` - Post-deployment verification
- `asdev-rollback.sh` - Rollback to previous version
- `asdev-release-gc.sh` - Release garbage collection

### 10.2 Dry-run Mode
All scripts support `--dry-run` mode for testing without making changes.
Without `--approve-phrase`, deploy and rollback scripts default to dry-run.

### 10.3 Common Flags
- `--site <name>`: Target site (required)
- `--environment <env>`: staging or production (required)
- `--commit <sha>`: Git commit SHA (required)
- `--dry-run`: Preview changes without applying
- `--check`: Run validation only
- `--approve-phrase <phrase>`: Approval gate phrase