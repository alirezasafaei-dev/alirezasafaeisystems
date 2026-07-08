# ASDEV Deployment Standard

**Version:** 1.0
**Last Updated:** 2026-07-08
**Scope:** All production site deployments

---

## 1. Overview

This document defines the standard deployment process for all ASDEV sites. All deployments must follow this standard to ensure consistency, safety, and auditability.

---

## 2. Deployment Pipeline

### 2.1 Pre-deployment Phase
1. **Preflight Checks** (`asdev-preflight.sh`)
   - Validate site exists in registry
   - Check deploy path accessibility
   - Verify backup path exists
   - Check for conflicting deployments
   - Validate environment configuration

2. **Change Detection** (built into deploy script)
   - Compare current and new versions
   - Classify changes: docs, assets, deps, source, config, migration
   - Generate change manifest

### 2.2 Deployment Phase
1. **Backup Creation**
   - Create timestamped backup of current version
   - Store in backup path from registry
   - Verify backup integrity

2. **Deployment Execution** (`asdev-deploy.sh`)
   - Apply changes based on change manifest
   - Record deployment metadata
   - Update deployment log

3. **Health Verification** (`asdev-healthcheck.sh`)
   - Run health checks against deployed site
   - Verify HTTP response codes
   - Check critical endpoints
   - Validate static assets

### 2.3 Post-deployment Phase
1. **Rollback Readiness** (`asdev-rollback.sh`)
   - Maintain rollback capability
   - Store rollback metadata
   - Test rollback mechanism (dry-run)

2. **Release Cleanup** (`asdev-release-gc.sh`)
   - Quarantine old releases
   - Delete quarantined releases after validation period
   - Maintain release history

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

### 4.1 Standard Deployment
- No special approval required
- Automatic deployment for non-critical sites

### 4.2 Critical Site Deployment
- **Approval Phrase:** `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`
- Must be provided for any production deployment to `persiantoolbox.ir`
- Interactive confirmation required

### 4.3 Release Garbage Collection
- **Approval Phrase:** `APPROVE_IRAN_PROD_DELETE_QUARANTINED_NON_CRITICAL`
- Required for deleting quarantined releases
- Applies to non-critical sites only

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

### 6.1 Automatic Rollback
- Triggered on health check failure
- Restores previous version from backup
- Records rollback event

### 6.2 Manual Rollback
- Use `asdev-rollback.sh` with version identifier
- Requires confirmation
- Records rollback event

---

## 7. Release Garbage Collection

### 7.1 Quarantine Period
- Releases older than 7 days are quarantined
- Quarantined releases are marked for deletion
- 24-hour grace period before deletion

### 7.2 Deletion Rules
- Only non-critical sites can have quarantined releases deleted
- Critical site releases are preserved indefinitely
- Deletion requires approval phrase

---

## 8. Monitoring and Alerts

### 8.1 Health Checks
- Run after every deployment
- Check HTTP endpoints
- Verify static asset availability
- Validate application responses

### 8.2 Failure Handling
- Automatic rollback on health check failure
- Alert deployment team
- Log failure details

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

### 10.3 Modes
- `--dry-run`: Preview changes without applying
- `--check`: Run validation only
- `--healthcheck-only`: Run health checks only