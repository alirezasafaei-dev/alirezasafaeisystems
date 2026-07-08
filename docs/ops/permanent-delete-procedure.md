# Permanent Delete Procedure

**Document Version:** 1.0
**Last Updated:** 2026-07-08
**Classification:** INTERNAL - PRODUCTION OPERATIONS

---

## Overview

This document defines the procedure for permanently deleting quarantined non-critical sites from IRAN_PROD. This is an **irreversible operation** that requires explicit owner approval.

---

## Prerequisites

1. Site must be in quarantine status (via `quarantine-non-critical.sh`)
2. Minimum 7-day quarantine period must have elapsed
3. Owner must provide approval phrase: `APPROVE_IRAN_PROD_DELETE_QUARANTINED_NON_CRITICAL`
4. Backup of quarantined site must exist and be verified

---

## Safety Checks

Before any deletion, the following must be verified:

| Check | Script | Required |
|-------|--------|----------|
| Site is quarantined | `ls /srv/asdev/quarantine/non-critical-sites/<site>/` | Yes |
| Quarantine age >= 7 days | Manual verification | Yes |
| Backup exists | `ls /srv/asdev/backups/<site>/` | Yes |
| Not CRITICAL_SITE | Automatic | Yes |
| Owner approval phrase | Manual input | Yes |

---

## Deletion Steps

### Step 1: Verify Quarantine Status

```bash
# List quarantined sites
ls -la /srv/asdev/quarantine/non-critical-sites/

# Verify specific site is quarantined
QUARANTINE_DIR="/srv/asdev/quarantine/non-critical-sites/<site-name>/LATEST"
if [[ -d "$QUARANTINE_DIR" ]]; then
    echo "Site is quarantined at: $QUARANTINE_DIR"
    cat "$QUARANTINE_DIR/metadata.json"
else
    echo "ERROR: Site is not quarantined"
    exit 1
fi
```

### Step 2: Verify Quarantine Age

```bash
# Check quarantine timestamp from metadata
METADATA="$QUARANTINE_DIR/metadata.json"
QUARANTINE_TIME=$(jq -r '.quarantine_timestamp' "$METADATA")
QUARANTINE_EPOCH=$(date -d "$QUARANTINE_TIME" +%s)
NOW_EPOCH=$(date +%s)
AGE_DAYS=$(( (NOW_EPOCH - QUARANTINE_EPOCH) / 86400 ))

if [[ $AGE_DAYS -lt 7 ]]; then
    echo "ERROR: Quarantine age is $AGE_DAYS days (minimum 7 required)"
    exit 1
fi

echo "Quarantine age: $AGE_DAYS days - OK"
```

### Step 3: Verify Backup Exists

```bash
SITE_NAME="<site-name>"
BACKUP_DIR="/srv/asdev/backups/${SITE_NAME}"

if [[ -d "$BACKUP_DIR" ]] && [[ $(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l) -gt 0 ]]; then
    echo "Backup verified at: $BACKUP_DIR"
    ls -la "$BACKUP_DIR"
else
    echo "ERROR: No backup found for $SITE_NAME"
    exit 1
fi
```

### Step 4: Request Approval

```bash
echo "=========================================="
echo "PERMANENT DELETE APPROVAL REQUIRED"
echo "=========================================="
echo ""
echo "Site: $SITE_NAME"
echo "Quarantine Path: $QUARANTINE_DIR"
echo "Backup Path: $BACKUP_DIR"
echo "Quarantine Age: $AGE_DAYS days"
echo ""
echo "Required approval phrase: APPROVE_IRAN_PROD_DELETE_QUARANTINED_NON_CRITICAL"
echo ""
read -p "Enter approval phrase: " APPROVAL
if [[ "$APPROVAL" != "APPROVE_IRAN_PROD_DELETE_QUARANTINED_NON_CRITICAL" ]]; then
    echo "ERROR: Invalid approval phrase. Deletion cancelled."
    exit 1
fi
echo "Approval confirmed."
```

### Step 5: Execute Deletion

```bash
echo "DELETING quarantine directory: $QUARANTINE_DIR"
rm -rf "$QUARANTINE_DIR"
echo "Quarantine directory removed."

echo "Cleaning up LATEST symlink..."
QUARANTINE_BASE="/srv/asdev/quarantine/non-critical-sites/${SITE_NAME}"
rm -f "$QUARANTINE_BASE/LATEST"
rmdir "$QUARANTINE_BASE" 2>/dev/null || true

echo "Permanent delete complete for: $SITE_NAME"
```

---

## Rollback

**There is no rollback for permanent deletion.**

Before executing Step 5, ensure:

1. Backup is verified and accessible
2. Site is confirmed non-critical
3. No active users depend on the site
4. Owner approval is documented

---

## Post-Deletion Verification

```bash
# Verify deletion
if [[ ! -d "/srv/asdev/quarantine/non-critical-sites/$SITE_NAME" ]]; then
    echo "✓ Quarantine directory removed"
else
    echo "✗ Quarantine directory still exists"
fi

# Verify backup still exists
if [[ -d "/srv/asdev/backups/$SITE_NAME" ]]; then
    echo "✓ Backup preserved at: /srv/asdev/backups/$SITE_NAME"
else
    echo "⚠ No backup found"
fi
```

---

## Documentation

After deletion, record in deployment log:

```
[<timestamp>] PERMANENT_DELETE <site_name> quarantine_dir=<path> backup_preserved=<yes/no> approved_by=<user>
```

---

**Warning:** This operation is irreversible. Always verify quarantine age, backup existence, and owner approval before proceeding.
