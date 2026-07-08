#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Quarantine Non-Critical Sites
# =============================================================================
# Safely moves non-critical sites to quarantine. Never deletes.
#
# Safety:
#   - DRY_RUN=true by default (must explicitly enable live mode)
#   - Requires --allowlist <path> with confirmed safe-to-quarantine sites
#   - Refuses CRITICAL_SITE (persiantoolbox / persiantoolbox.ir)
#   - Refuses unknown sites not in the allowlist
#   - Live mode requires approval phrase: APPROVE_IRAN_PROD_QUARANTINE_NON_CRITICAL
#   - Live mode never deletes — only moves to quarantine path
#   - Does not reload nginx automatically
#   - Does not stop PM2 automatically unless allowlist plan marks process as non-critical
#   - Creates recovery manifest for every action
#
# Usage:
#   ./quarantine-non-critical.sh --allowlist <path> [--dry-run|--live] <site-name>
# =============================================================================

CRITICAL_SITES=("persiantoolbox" "persiantoolbox.ir")
QUARANTINE_BASE="/srv/asdev/quarantine/non-critical-sites"
DEPLOY_BASE="/srv/asdev/sites"
APPROVAL_PHRASE="APPROVE_IRAN_PROD_QUARANTINE_NON_CRITICAL"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"; }
warn()  { echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR:${NC} $1" >&2; exit 1; }
ok()    { echo -e "${GREEN}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK:${NC} $1"; }

DRY_RUN=true
ALLOWLIST_FILE=""
SITE_NAME=""
PM2_STOP=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <site-name>

Quarantine a non-critical site by moving it to the quarantine path.
Never deletes. Dry-run by default.

Required:
  --allowlist <path>     Path to allowlist file (one site per line)
  <site-name>            Site to quarantine (positional or last argument)

Optional:
  --dry-run              Preview changes without applying (DEFAULT)
  --live                 Execute quarantine (requires approval phrase)
  --pm2-stop             Allow PM2 process stop (if plan marks process non-critical)
  -h, --help             Show this help

Safety:
  - CRITICAL_SITE (persiantoolbox) is always refused
  - Unknown sites not in allowlist are always refused
  - Live mode requires approval phrase: $APPROVAL_PHRASE
  - No permanent deletion — quarantine only
  - No automatic nginx reload
  - No automatic PM2 stop unless --pm2-stop is passed and allowlist plan confirms

Examples:
  $(basename "$0") --allowlist /tmp/quarantine-allowlist.txt auditsystems
  $(basename "$0") --allowlist /tmp/quarantine-allowlist.txt --live auditsystems
EOF
}

is_critical() {
    local site="$1"
    for crit in "${CRITICAL_SITES[@]}"; do
        if [[ "$site" == "$crit" ]]; then
            return 0
        fi
    done
    return 1
}

is_in_allowlist() {
    local site="$1"
    if [[ -z "$ALLOWLIST_FILE" ]] || [[ ! -f "$ALLOWLIST_FILE" ]]; then
        return 1
    fi
    grep -qxE "$site" "$ALLOWLIST_FILE" 2>/dev/null
}

is_in_plan() {
    local site="$1"
    if [[ -z "$ALLOWLIST_FILE" ]] || [[ ! -f "$ALLOWLIST_FILE" ]]; then
        return 1
    fi
    grep -qE "^[^#]*${site}" "$ALLOWLIST_FILE" 2>/dev/null
}

plan_marks_non_critical() {
    local site="$1"
    if [[ -z "$ALLOWLIST_FILE" ]] || [[ ! -f "$ALLOWLIST_FILE" ]]; then
        return 1
    fi
    grep -qE "^${site}\|non-critical" "$ALLOWLIST_FILE" 2>/dev/null
}

create_recovery_manifest() {
    local site="$1" quarantine_dir="$2"
    local manifest_file="${quarantine_dir}/recovery-manifest.json"
    local timestamp
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    cat > "$manifest_file" <<MANIFEST
{
  "site": "$site",
  "quarantined_at": "$timestamp",
  "no_deletion_occurred": true,
  "pm2_was_not_stopped": $([ "$PM2_STOP" == "true" ] && echo "false" || echo "true"),
  "nginx_was_not_reloaded": true,
  "original_path": "${DEPLOY_BASE}/${site}",
  "quarantine_path": "$quarantine_dir",
  "recovery_command": "mv '$quarantine_dir' '${DEPLOY_BASE}/${site}'",
  "dry_run": $([ "$DRY_RUN" == "true" ] && echo "true" || echo "false")
}
MANIFEST
    log "Recovery manifest created: $manifest_file"
}

quarantine_site() {
    local site="$1"
    local site_dir="${DEPLOY_BASE}/${site}"
    local timestamp
    timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
    local quarantine_dir="${QUARANTINE_BASE}/${site}/${timestamp}"

    log "Site: $site"
    log "Source: $site_dir"
    log "Quarantine target: $quarantine_dir"
    log "Dry run: $DRY_RUN"

    if [[ ! -d "$site_dir" ]]; then
        error "Site directory does not exist: $site_dir"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would create quarantine directory: $quarantine_dir"
        log "[DRY RUN] Would move $site_dir -> $quarantine_dir"
        if [[ "$PM2_STOP" == "true" ]] && plan_marks_non_critical "$site"; then
            log "[DRY RUN] Would stop PM2 processes for $site (plan marks as non-critical)"
        else
            log "[DRY RUN] Would NOT stop PM2 (no --pm2-stop or plan does not mark as non-critical)"
        fi
        log "[DRY RUN] Would NOT reload nginx"
        log "[DRY RUN] Would create recovery manifest"
        ok "Dry run complete — no changes applied"
        return 0
    fi

    mkdir -p "$quarantine_dir"

    mv "$site_dir" "$quarantine_dir/"

    ok "Moved $site -> $quarantine_dir"

    create_recovery_manifest "$site" "$quarantine_dir"

    if [[ "$PM2_STOP" == "true" ]] && plan_marks_non_critical "$site"; then
        log "PM2 stop requested but NOT executing automatically — operator must verify and stop manually"
    else
        log "PM2 processes NOT stopped (automatic stop disabled)"
    fi

    log "Nginx NOT reloaded — operator must review and reload manually"

    ok "Quarantine complete for $site"
    log "Recovery: mv '$quarantine_dir/${site}' '${site_dir}'"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --allowlist)  ALLOWLIST_FILE="$2"; shift 2 ;;
            --dry-run)    DRY_RUN=true; shift ;;
            --live)       DRY_RUN=false; shift ;;
            --pm2-stop)   PM2_STOP=true; shift ;;
            -h|--help)    usage; exit 0 ;;
            -*)           error "Unknown option: $1" ;;
            *)            SITE_NAME="$1"; shift ;;
        esac
    done

    [[ -z "$SITE_NAME" ]] && error "Missing required site name. Usage: $(basename "$0") --allowlist <path> <site-name>"

    if [[ -z "$ALLOWLIST_FILE" ]]; then
        error "Missing required --allowlist <path>. A generated allowlist file is required."
    fi

    if [[ ! -f "$ALLOWLIST_FILE" ]]; then
        error "Allowlist file not found: $ALLOWLIST_FILE"
    fi

    if is_critical "$SITE_NAME"; then
        error "REFUSED: $SITE_NAME is a CRITICAL_SITE — quarantine is not permitted"
    fi

    if ! is_in_allowlist "$SITE_NAME"; then
        error "REFUSED: $SITE_NAME is not in the allowlist ($ALLOWLIST_FILE) — unknown or unclassified site"
    fi

    if [[ "$DRY_RUN" == "false" ]]; then
        log "Live mode — checking approval phrase..."
        if [[ "${APPROVE_PHRASE_INPUT:-}" != "$APPROVAL_PHRASE" ]]; then
            error "Live mode requires approval phrase. Set APPROVE_PHRASE_INPUT=$APPROVAL_PHRASE before running."
        fi
        log "Approval phrase verified"
    fi

    quarantine_site "$SITE_NAME"
}

APPROVE_PHRASE_INPUT="${APPROVE_PHRASE_INPUT:-}"
main "$@"
