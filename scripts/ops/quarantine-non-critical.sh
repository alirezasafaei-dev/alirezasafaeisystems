#!/bin/bash

# QUARANTINE NON-CRITICAL SITES Script (Phase F)
# Safely disables and archives non-critical sites to quarantine
# NEVER RUN THIS SCRIPT WITHOUT EXPLICIT APPROVAL

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

APPROVAL_PHRASE="APPROVE_IRAN_PROD_QUARANTINE_NON_CRITICAL"
CRITICAL_SITE="persiantoolbox.ir"
DEPLOY_BASE="/srv/asdev/sites"
QUARANTINE_BASE="/srv/asdev/quarantine/non-critical-sites"
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")

# ============================================================================
# DRY-RUN MODE
# ============================================================================

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    shift
fi

# ============================================================================
# HELPERS
# ============================================================================

log() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $1"
}

log_error() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] ERROR: $1" >&2
}

dry_run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would execute: $1"
        return 1
    fi
    return 0
}

# ============================================================================
# APPROVAL GATE
# ============================================================================

if [[ $# -lt 1 ]] || [[ "$1" != "$APPROVAL_PHRASE" ]]; then
    log_error "Approval required to run quarantine script"
    echo "Usage: $0 [--dry-run] $APPROVAL_PHRASE <site-name>" >&2
    echo "This script will disable and archive a site to quarantine" >&2
    exit 1
fi

# Get site name from second argument
SITE_NAME="${2:-}"
if [[ -z "$SITE_NAME" ]]; then
    log_error "Site name required as second argument"
    echo "Usage: $0 $APPROVAL_PHRASE <site-name>" >&2
    exit 1
fi

# Validate site name format (alphanumeric and hyphens only)
if [[ ! "$SITE_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
    log_error "Invalid site name: must be alphanumeric with hyphens"
    exit 1
fi

# ============================================================================
# CRITICAL SITE PROTECTION
# ============================================================================

if [[ "$SITE_NAME" == "$CRITICAL_SITE" ]]; then
    log_error "CRITICAL SITE CANNOT BE QUARANTINED: $CRITICAL_SITE"
    echo "The site $CRITICAL_SITE is marked as CRITICAL and cannot be quarantined" >&2
    exit 1
fi

# Also check for common variations
if [[ "$SITE_NAME" == "persiantoolbox" ]] || [[ "$SITE_NAME" == "persiantoolbox.ir" ]]; then
    log_error "CRITICAL SITE CANNOT BE QUARANTINED: $CRITICAL_SITE"
    echo "The site $CRITICAL_SITE is marked as CRITICAL and cannot be quarantined" >&2
    exit 1
fi

# ============================================================================
# SITE VERIFICATION
# ============================================================================

log "Verifying site identity: $SITE_NAME"

# Check if site directory exists
SITE_DIR="${DEPLOY_BASE}/${SITE_NAME}"
if [[ ! -d "$SITE_DIR" ]]; then
    log_error "Site directory not found: $SITE_DIR"
    echo "Available sites in $DEPLOY_BASE:" >&2
    ls -1 "$DEPLOY_BASE" 2>/dev/null || echo "  (no sites found)" >&2
    exit 1
fi

# Verify site identity - check for package.json or other identity markers
if [[ -f "$SITE_DIR/package.json" ]]; then
    SITE_IDENTITY=$(cat "$SITE_DIR/package.json" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 || echo "unknown")
    log "Site identity confirmed: $SITE_IDENTITY"
elif [[ -f "$SITE_DIR/ecosystem.config.js" ]] || [[ -f "$SITE_DIR/pm2.config.js" ]]; then
    log "Site identity confirmed via PM2 config"
elif [[ -f "$SITE_DIR/.env" ]] || [[ -f "$SITE_DIR/config.json" ]]; then
    log "Site identity confirmed via configuration files"
else
    log_error "Could not verify site identity at $SITE_DIR"
    echo "Quarantine requires positive site identification" >&2
    exit 1
fi

# ============================================================================
# QUARANTINE PREPARATION
# ============================================================================

QUARANTINE_DIR="${QUARANTINE_BASE}/${SITE_NAME}/${TIMESTAMP}"

log "Quarantine target: $QUARANTINE_DIR"
log "Mode: $(if $DRY_RUN; then echo 'DRY-RUN'; else echo 'LIVE'; fi)"

# ============================================================================
# STEP 1: SAVE PM2 STATE (BEFORE)
# ============================================================================

log "Step 1: Saving PM2 state before quarantine..."

if command -v pm2 >/dev/null 2>&1; then
    PM2_STATE_BEFORE=$(pm2 jlist 2>/dev/null || echo "[]")
    
    if dry_run_cmd "Save PM2 process list"; then
        echo "$PM2_STATE_BEFORE" > "/tmp/pm2_state_before_${SITE_NAME}.json"
    fi
else
    log "PM2 not found - skipping PM2 operations"
    PM2_STATE_BEFORE="[]"
fi

# ============================================================================
# STEP 2: STOP PM2 PROCESS
# ============================================================================

log "Step 2: Stopping PM2 process for $SITE_NAME..."

if command -v pm2 >/dev/null 2>&1; then
    # Find the PM2 process name for this site
    PM2_PROCESS_NAME=$(echo "$PM2_STATE_BEFORE" | jq -r '.[] | select(.name | test("'"$SITE_NAME"'"; "i")) | .name' 2>/dev/null | head -1 || echo "")
    
    if [[ -z "$PM2_PROCESS_NAME" ]]; then
        # Try matching by ecosystem config path
        PM2_PROCESS_NAME=$(echo "$PM2_STATE_BEFORE" | jq -r '.[] | select(.pm2_env.pm_cwd // "" | test("'"$SITE_DIR"'")) | .name' 2>/dev/null | head -1 || echo "")
    fi
    
    if [[ -n "$PM2_PROCESS_NAME" ]]; then
        log "Found PM2 process: $PM2_PROCESS_NAME"
        if dry_run_cmd "Stop PM2 process $PM2_PROCESS_NAME"; then
            pm2 stop "$PM2_PROCESS_NAME" 2>/dev/null || true
            log "Stopped PM2 process: $PM2_PROCESS_NAME"
        fi
    else
        log "No PM2 process found matching $SITE_NAME"
    fi
    
    # Save PM2 state after stop
    if dry_run_cmd "Save PM2 state after stop"; then
        PM2_STATE_AFTER=$(pm2 jlist 2>/dev/null || echo "[]")
        echo "$PM2_STATE_AFTER" > "/tmp/pm2_state_after_${SITE_NAME}.json"
    fi
else
    log "PM2 not found - skipping"
fi

# ============================================================================
# STEP 3: FIND AND DISABLE NGINX CONFIGS
# ============================================================================

log "Step 3: Finding and archiving nginx configs..."

NGINX_CONF_DIR="/etc/nginx"
NGINX_QUARANTINE_DIR="${QUARANTINE_DIR}/nginx"

if [[ -d "$NGINX_CONF_DIR" ]]; then
    # Find nginx configs that reference this site
    SITE_NGINX_FILES=$(grep -rl "$SITE_NAME" "$NGINX_CONF_DIR" 2>/dev/null || echo "")
    
    if [[ -n "$SITE_NGINX_FILES" ]]; then
        mkdir -p "$NGINX_QUARANTINE_DIR"
        
        while IFS= read -r conf_file; do
            if [[ -f "$conf_file" ]]; then
                log "Archiving nginx config: $conf_file"
                
                if dry_run_cmd "Copy nginx config $conf_file to quarantine"; then
                    cp "$conf_file" "$NGINX_QUARANTINE_DIR/"
                fi
                
                # Create redacted copy for metadata
                REDACTED_FILE="${NGINX_QUARANTINE_DIR}/$(basename "$conf_file").redacted"
                if dry_run_cmd "Create redacted nginx config"; then
                    sed -E \
                        -e 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[REDACTED_IP]/g' \
                        -e 's/(api[_-]?key|password|secret|token|auth)[[:space:]]*[:=][[:space:]]*["\x27]?[^ "\x27,;]+["\x27]?/\1=[REDACTED]/gi' \
                        "$conf_file" > "$REDACTED_FILE"
                fi
            fi
        done <<< "$SITE_NGINX_FILES"
    else
        log "No nginx configs found referencing $SITE_NAME"
    fi
else
    log "Nginx configuration directory not found"
fi

# ============================================================================
# STEP 4: MOVE APP DIRECTORY TO QUARANTINE
# ============================================================================

log "Step 4: Moving app directory to quarantine..."

if dry_run_cmd "Create quarantine directory structure"; then
    mkdir -p "$QUARANTINE_DIR/app"
fi

if [[ -d "$SITE_DIR" ]]; then
    if dry_run_cmd "Move $SITE_DIR to $QUARANTINE_DIR/app/"; then
        mv "$SITE_DIR" "${QUARANTINE_DIR}/app/${SITE_NAME}"
        log "Moved app directory to quarantine"
    fi
fi

# ============================================================================
# STEP 5: CREATE METADATA.JSON
# ============================================================================

log "Step 5: Creating quarantine metadata..."

METADATA_FILE="${QUARANTINE_DIR}/metadata.json"

if dry_run_cmd "Create metadata.json"; then
    cat > "$METADATA_FILE" << EOF
{
  "quarantine_id": "${SITE_NAME}-${TIMESTAMP}",
  "site_name": "${SITE_NAME}",
  "quarantine_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "quarantine_type": "non-critical",
  "critical_site_protection": "active",
  "pre_quarantine_state": {
    "pm2_process_found": $(if [[ -n "${PM2_PROCESS_NAME:-}" ]]; then echo "true"; else echo "false"; fi),
    "pm2_process_name": "${PM2_PROCESS_NAME:-null}",
    "nginx_configs_found": $(if [[ -n "${SITE_NGINX_FILES:-}" ]]; then echo "true"; else echo "false"; fi),
    "nginx_config_count": $(echo "${SITE_NGINX_FILES:-}" | grep -c "." 2>/dev/null || echo "0"),
    "app_directory_size": "$(du -sh "${SITE_DIR}" 2>/dev/null | awk '{print $1}' || echo "unknown")"
  },
  "quarantine_paths": {
    "original_site_dir": "${SITE_DIR}",
    "quarantine_dir": "${QUARANTINE_DIR}",
    "nginx_configs": "${NGINX_QUARANTINE_DIR}",
    "app_directory": "${QUARANTINE_DIR}/app/${SITE_NAME}"
  },
  "recovery_instructions": {
    "steps": [
      "1. Review the quarantined files in ${QUARANTINE_DIR}",
      "2. Verify nginx configs for any required changes",
      "3. Move app directory back: mv ${QUARANTINE_DIR}/app/${SITE_NAME} ${DEPLOY_BASE}/${SITE_NAME}",
      "4. Restore nginx configs: cp ${NGINX_QUARANTINE_DIR}/*.conf /etc/nginx/conf.d/",
      "5. Reload nginx: nginx -t && systemctl reload nginx",
      "6. Start PM2 process: pm2 start ecosystem.config.js (from site directory)"
    ],
    "estimated_downtime": "5-15 minutes",
    "requires_nginx_reload": true,
    "requires_pm2_restart": true
  },
  "pm2_state_before": $(cat "/tmp/pm2_state_before_${SITE_NAME}.json" 2>/dev/null || echo "[]"),
  "pm2_state_after": $(cat "/tmp/pm2_state_after_${SITE_NAME}.json" 2>/dev/null || echo "[]"),
  "approved_by": "system",
  "approval_phrase": "${APPROVAL_PHRASE}",
  "dry_run": $DRY_RUN
}
EOF
    
    log "Metadata created: $METADATA_FILE"
fi

# ============================================================================
# STEP 6: CREATE LATEST SYMLINK
# ============================================================================

log "Step 6: Creating LATEST symlink..."

LATEST_LINK="${QUARANTINE_BASE}/${SITE_NAME}/LATEST"

if dry_run_cmd "Create LATEST symlink"; then
    # Remove existing LATEST symlink if present
    rm -f "$LATEST_LINK"
    
    # Create new symlink
    ln -sf "$QUARANTINE_DIR" "$LATEST_LINK"
    log "LATEST symlink created: $LATEST_LINK -> $QUARANTINE_DIR"
fi

# ============================================================================
# STEP 7: CLEANUP TEMP FILES
# ============================================================================

log "Step 7: Cleaning up temporary files..."

rm -f "/tmp/pm2_state_before_${SITE_NAME}.json"
rm -f "/tmp/pm2_state_after_${SITE_NAME}.json"

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "=========================================="
echo "  QUARANTINE COMPLETE"
echo "=========================================="
echo ""
echo "  Site: $SITE_NAME"
echo "  Mode: $(if $DRY_RUN; then echo 'DRY-RUN'; else echo 'LIVE'; fi)"
echo "  Quarantine ID: ${SITE_NAME}-${TIMESTAMP}"
echo "  Quarantine Path: $QUARANTINE_DIR"
echo ""
echo "  To restore this site:"
echo "    Review: $QUARANTINE_DIR"
echo "    LATEST: $LATEST_LINK"
echo ""
echo "  Metadata: $METADATA_FILE"
echo "=========================================="
echo ""
log "Quarantine completed at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
