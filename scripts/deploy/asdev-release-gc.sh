#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
REGISTRY="$PROJECT_ROOT/deploy/registry.tsv"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SITE_NAME=""
ENVIRONMENT=""
COMMIT=""
DRY_RUN=false
CHECK_MODE=false
APPROVE_PHRASE=""
QUARANTINE_DAYS=7
KEEP_RELEASES=5

COL_SITE_ID=1
COL_DISPLAY_NAME=2
COL_PRIORITY=3
COL_PROTECTED=4
COL_REPO_PATH=5
COL_ARTIFACT_PATH=6
COL_PROD_BASE=7
COL_STAGING_BASE=8
COL_SHARED_PATH=9
COL_HC_MODE=10
COL_HC_HOST_ALIAS=11
COL_HC_PORT=12
COL_HC_PATH=13
COL_RUNTIME=14
COL_PROCESS_NAMES=15
COL_BUILD_CMD_ID=16
COL_START_CMD_ID=17
COL_ENV_ALIAS=18
COL_DEPLOY_STRATEGY=19
COL_ROLLBACK_STRATEGY=20

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Manage release garbage collection (quarantine only by default).

Required:
  --site <name>              Site to manage (must exist in registry)
  --environment <env>        Target environment: staging|production
  --commit <sha>             Git commit SHA (for audit trail)

Optional:
  --dry-run                  Preview changes without applying
  --check                    Run validation only
  --approve-phrase <phrase>  Required for actual deletion: APPROVE_RELEASE_DELETE
  --quarantine-days <n>      Days before quarantining (default: 7)
  --keep-releases <n>        Releases to keep (default: 5)
  -h, --help                 Show this help

Examples:
  $(basename "$0") --site auditsystems --environment staging --commit abc1234
  $(basename "$0") --site auditsystems --environment staging --commit abc1234 --dry-run
  $(basename "$0") --site auditsystems --environment staging --commit abc1234 --approve-phrase APPROVE_RELEASE_DELETE
EOF
}

log()   { echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"; }
warn()  { echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR:${NC} $1" >&2; exit 1; }
ok()    { echo -e "${GREEN}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK:${NC} $1"; }

registry_field() {
    local site="$1" field="$2"
    awk -F'\t' -v site="$site" -v col="$field" '$1 == site {print $col}' "$REGISTRY"
}

get_field() { registry_field "$SITE_NAME" "$2"; }

validate_args() {
    [[ -z "$SITE_NAME" ]] && error "Missing required --site"
    [[ -z "$ENVIRONMENT" ]] && error "Missing required --environment (staging|production)"
    [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]] && error "Invalid environment: $ENVIRONMENT"
    [[ -z "$COMMIT" ]] && error "Missing required --commit"
    grep -q "^${SITE_NAME}	" "$REGISTRY" 2>/dev/null || error "Site '$SITE_NAME' not found in registry"
}

is_protected() {
    local val
    val=$(get_field "$COL_PROTECTED")
    [[ "$val" == "true" ]]
}

get_deploy_base() {
    if [[ "$ENVIRONMENT" == "production" ]]; then
        get_field "$COL_PROD_BASE"
    else
        get_field "$COL_STAGING_BASE"
    fi
}

get_current_release() {
    local deploy_base="$1"
    local current_link="${deploy_base}/current"
    if [[ -L "$current_link" ]]; then
        basename "$(readlink -f "$current_link")"
    fi
}

list_releases() {
    local deploy_base="$1"
    if [[ -d "${deploy_base}/releases" ]]; then
        ls -1dt "${deploy_base}/releases"/*/ 2>/dev/null | xargs -I{} basename {} || true
    fi
}

quarantine_release() {
    local deploy_base="$1" version="$2"
    local release_dir="${deploy_base}/releases/${version}"
    local quarantine_dir="${deploy_base}/.quarantine"
    [[ ! -d "$release_dir" ]] && { warn "Release $version not found"; return 1; }
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would quarantine: $version -> $quarantine_dir/$version"
        return 0
    fi
    mkdir -p "$quarantine_dir"
    mv "$release_dir" "${quarantine_dir}/${version}"
    ok "Quarantined: $version"
}

delete_quarantined() {
    local deploy_base="$1" version="$2"
    local quarantine_dir="${deploy_base}/.quarantine"
    local q_path="${quarantine_dir}/${version}"
    [[ ! -d "$q_path" ]] && { warn "Quarantined release $version not found"; return 1; }
    if is_protected; then
        error "Cannot delete quarantined release from protected site"
    fi
    if [[ "$APPROVE_PHRASE" != "APPROVE_RELEASE_DELETE" ]]; then
        error "Deletion requires --approve-phrase APPROVE_RELEASE_DELETE"
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would delete quarantined: $version"
        return 0
    fi
    rm -rf "$q_path"
    ok "Deleted quarantined release: $version"
}

cleanup_quarantined_aged() {
    local deploy_base="$1"
    local quarantine_dir="${deploy_base}/.quarantine"
    [[ ! -d "$quarantine_dir" ]] && return 0
    log "Checking aged quarantined releases (>${QUARANTINE_DAYS} days)..."
    while IFS= read -r q_release; do
        [[ -z "$q_release" ]] && continue
        local q_path="${quarantine_dir}/${q_release}"
        local age_secs=$(( $(date +%s) - $(stat -c %Y "$q_path") ))
        local age_days=$(( age_secs / 86400 ))
        if [[ $age_days -ge $QUARANTINE_DAYS ]]; then
            if is_protected; then
                log "Skipping protected site release: $q_release (${age_days}d old)"
            elif [[ "$APPROVE_PHRASE" == "APPROVE_RELEASE_DELETE" ]]; then
                delete_quarantined "$deploy_base" "$q_release"
            else
                log "Release $q_release is ${age_days}d old (threshold: ${QUARANTINE_DAYS}d) — requires APPROVE_RELEASE_DELETE to delete"
            fi
        else
            log "Release $q_release: ${age_days}d old (threshold: ${QUARANTINE_DAYS}d)"
        fi
    done < <(ls -1 "$quarantine_dir" 2>/dev/null || true)
}

run_gc() {
    echo ""
    echo "========================================"
    echo "  RELEASE GC: $SITE_NAME ($ENVIRONMENT)"
    echo "  COMMIT: $COMMIT"
    echo "========================================"
    echo ""
    local deploy_base current_release
    deploy_base=$(get_deploy_base)
    current_release=$(get_current_release "$deploy_base")
    log "Current release: ${current_release:-none}"
    local releases
    releases=$(list_releases "$deploy_base")
    local release_count=0
    while IFS= read -r r; do [[ -n "$r" ]] && ((release_count++)) || true; done <<< "$releases"
    log "Total releases: $release_count"
    local keep_count=$((KEEP_RELEASES + 1))
    if [[ $release_count -le $keep_count ]]; then
        log "No releases to quarantine (keeping $KEEP_RELEASES + current)"
    else
        log "Quarantining excess releases (keeping $KEEP_RELEASES + current)..."
        local quarantined=0
        while IFS= read -r release; do
            [[ -z "$release" ]] && continue
            [[ "$release" == "$current_release" ]] && continue
            if [[ $quarantined -ge $KEEP_RELEASES ]]; then
                quarantine_release "$deploy_base" "$release" || true
            else
                ((quarantined++)) || true
            fi
        done <<< "$releases"
    fi
    cleanup_quarantined_aged "$deploy_base"
    echo ""
    echo "========================================"
    ok "GC complete for $SITE_NAME"
    echo "========================================"
    echo ""
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --site)             SITE_NAME="$2"; shift 2 ;;
            --environment)      ENVIRONMENT="$2"; shift 2 ;;
            --commit)           COMMIT="$2"; shift 2 ;;
            --dry-run)          DRY_RUN=true; shift ;;
            --check)            CHECK_MODE=true; shift ;;
            --approve-phrase)   APPROVE_PHRASE="$2"; shift 2 ;;
            --quarantine-days)  QUARANTINE_DAYS="$2"; shift 2 ;;
            --keep-releases)    KEEP_RELEASES="$2"; shift 2 ;;
            -h|--help)          usage; exit 0 ;;
            *)                  error "Unknown option: $1" ;;
        esac
    done
    validate_args
    if [[ "$CHECK_MODE" == "true" ]]; then
        log "Check mode — validating GC config for $SITE_NAME"
        local deploy_base
        deploy_base=$(get_deploy_base)
        log "Deploy base: $deploy_base"
        log "Keep releases: $KEEP_RELEASES"
        log "Quarantine days: $QUARANTINE_DAYS"
        log "Protected: $(is_protected && echo true || echo false)"
        ok "Validation complete — no changes applied"
        exit 0
    fi
    run_gc
}

main "$@"
