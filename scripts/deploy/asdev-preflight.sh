#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/asdev-common.sh
source "${SCRIPT_DIR}/lib/asdev-common.sh"
PROJECT_ROOT="$(asdev_project_root_from "$SCRIPT_DIR")"
REGISTRY="$PROJECT_ROOT/deploy/registry.tsv"
# ensure common is loaded for port helpers

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
COL_PROD_PORT=12
COL_HC_PORT=12
COL_HC_PATH=13
COL_RUNTIME=14
COL_PROCESS_NAMES=15
COL_BUILD_CMD_ID=16
COL_START_CMD_ID=17
COL_ENV_ALIAS=18
COL_DEPLOY_STRATEGY=19
COL_ROLLBACK_STRATEGY=20
COL_STAGING_PORT=21

ERRORS=0
WARNINGS=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run pre-deployment checks for a site.

Required:
  --site <name>           Site to check (must exist in registry)
  --environment <env>     Target environment: staging|production
  --commit <sha>          Git commit SHA to validate

Optional:
  --dry-run               Preview checks without running
  --check                 Run validation only (alias)
  -h, --help              Show this help

Examples:
  $(basename "$0") --site auditsystems --environment staging --commit abc1234
  $(basename "$0") --site persiantoolbox --environment production --commit def5678 --dry-run
EOF
}

log()   { echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"; }
warn()  { echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN:${NC} $1"; ((WARNINGS++)) || true; }
error() { echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR:${NC} $1"; ((ERRORS++)) || true; }
ok()    { echo -e "${GREEN}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK:${NC} $1"; }

registry_field() {
    local site="$1" field="$2"
    awk -F'\t' -v site="$site" -v col="$field" '$1 == site {print $col}' "$REGISTRY"
}

get_field() { registry_field "$SITE_NAME" "$1"; }

validate_args() {
    [[ -z "$SITE_NAME" ]] && { error "Missing required --site"; return 1; }
    [[ -z "$ENVIRONMENT" ]] && { error "Missing required --environment (staging|production)"; return 1; }
    [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]] && { error "Invalid environment: $ENVIRONMENT"; return 1; }
    [[ -z "$COMMIT" ]] && { error "Missing required --commit"; return 1; }
    grep -q "^${SITE_NAME}	" "$REGISTRY" 2>/dev/null || { error "Site '$SITE_NAME' not found in registry"; return 1; }
    return 0
}

check_registry() {
    log "Checking registry..."
    if [[ ! -f "$REGISTRY" ]]; then
        error "Registry file not found: $REGISTRY"
        return 1
    fi
    ok "Registry found"
}

check_repo_path() {
    log "Checking repo path..."
    local repo_path full_path status
    repo_path=$(get_field "$COL_REPO_PATH")
    full_path="$(asdev_resolve_site_src "$PROJECT_ROOT" "$SITE_NAME" "$repo_path")"
    status="$(asdev_site_src_status "$full_path")"
    case "$status" in
        ready)
            ok "Source ready: $full_path"
            ;;
        partial)
            warn "Source partial (no package.json): $full_path"
            warn "Run: scripts/deploy/asdev-prepare-site-source.sh --site $SITE_NAME --apply"
            ;;
        *)
            warn "Source missing: $full_path"
            warn "Run: scripts/deploy/asdev-prepare-site-source.sh --site $SITE_NAME --apply"
            ;;
    esac
}

check_deploy_base() {
    log "Checking deploy base..."
    local deploy_base
    if [[ "$ENVIRONMENT" == "production" ]]; then
        deploy_base=$(get_field "$COL_PROD_BASE")
    else
        deploy_base=$(get_field "$COL_STAGING_BASE")
    fi
    if [[ -d "$deploy_base" ]]; then
        ok "Deploy base exists: $deploy_base"
    else
        warn "Deploy base does not exist yet (will be created on first deploy)"
    fi
}

check_shared_path() {
    log "Checking shared path..."
    local shared_path
    shared_path=$(get_field "$COL_SHARED_PATH")
    if [[ -d "$shared_path" ]]; then
        ok "Shared path exists: $shared_path"
    else
        warn "Shared path does not exist yet (will be created on first deploy)"
    fi
}

check_commit() {
    log "Checking commit $COMMIT..."
    local repo_path full_path
    repo_path=$(get_field "$COL_REPO_PATH")
    full_path="$(asdev_resolve_site_src "$PROJECT_ROOT" "$SITE_NAME" "$repo_path")"
    if [[ -d "$full_path" ]] && git -C "$full_path" rev-parse --verify "$COMMIT" >/dev/null 2>&1; then
        ok "Commit $COMMIT found in $full_path"
    else
        # External product repos use their own SHAs; ASDEV commit is audit trail only.
        warn "Commit $COMMIT not in site source (expected for external repos; audit trail only)"
    fi
}

check_healthcheck_endpoint() {
    log "Checking healthcheck endpoint..."
    local hc_mode hc_port hc_path prod_port staging_port
    hc_mode=$(get_field "$COL_HC_MODE")
    prod_port=$(get_field "$COL_PROD_PORT")
    staging_port=$(get_field "$COL_STAGING_PORT")
    hc_path=$(get_field "$COL_HC_PATH")
    hc_port=$(asdev_resolve_env_port "$ENVIRONMENT" "$prod_port" "$staging_port")
    if [[ "$prod_port" == "$staging_port" && -n "$prod_port" && "$prod_port" != "-" ]]; then
        error "Port isolation violation: prod_port == staging_port ($prod_port)"
        return 1
    fi
    ok "Port plan: prod=$prod_port staging=$staging_port active_env_port=$hc_port"
    if [[ "$hc_mode" == "none" ]]; then
        warn "Healthcheck mode is 'none' — no endpoint to check"
        return 0
    fi
    if [[ "$hc_mode" == "local-port" ]]; then
        if [[ -z "$hc_port" || "$hc_port" == "-" ]]; then
            warn "local-port mode but no port configured for $ENVIRONMENT"
            return 0
        fi
        if command -v curl >/dev/null 2>&1; then
            local http_code
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://127.0.0.1:${hc_port}${hc_path}" 2>/dev/null || echo "000")
            if [[ "$http_code" == "000" ]]; then
                warn "Healthcheck endpoint not reachable on :$hc_port (expected if not deployed)"
            elif [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then
                ok "Healthcheck endpoint reachable on :$hc_port (HTTP $http_code)"
            else
                warn "Healthcheck endpoint returned HTTP $http_code on :$hc_port"
            fi
        else
            warn "curl not available — skipping endpoint check"
        fi
    else
        warn "Healthcheck mode '$hc_mode' — skipping endpoint check"
    fi
}

check_port_collision_guard() {
    log "Checking port isolation guards..."
    local prod_port staging_port active
    prod_port=$(get_field "$COL_PROD_PORT")
    staging_port=$(get_field "$COL_STAGING_PORT")
    active=$(asdev_resolve_env_port "$ENVIRONMENT" "$prod_port" "$staging_port")
    if [[ "$prod_port" == "$staging_port" ]]; then
        error "Cannot deploy: prod_port and staging_port collide ($prod_port)"
        return 1
    fi
    # If deploying production while staging holds same port as production target — blocked by isolation above.
    # If target port is listening and this is production, warn strongly.
    if asdev_port_is_listening "$active"; then
        if [[ "$ENVIRONMENT" == "production" ]]; then
            warn "Target production port $active is currently listening — cutover must own/stop it before live start"
        else
            warn "Target staging port $active is currently listening — redeploy will restart owned runtime if pid matches"
        fi
    else
        ok "Target port $active is free"
    fi
}

check_disk_space() {
    log "Checking disk space..."
    local deploy_base check_path
    if [[ "$ENVIRONMENT" == "production" ]]; then
        deploy_base=$(get_field "$COL_PROD_BASE")
    else
        deploy_base=$(get_field "$COL_STAGING_BASE")
    fi
    # Prefer deploy_base when present; otherwise fall back to existing parents.
    if [[ -n "$deploy_base" && -d "$deploy_base" ]]; then
        check_path="$deploy_base"
    elif [[ -n "$deploy_base" && -d "$(dirname "$deploy_base")" ]]; then
        check_path="$(dirname "$deploy_base")"
        warn "Deploy base missing; checking parent path disk space"
    else
        check_path="/"
        warn "Deploy base unavailable; checking root filesystem disk space"
    fi
    local avail_kb
    avail_kb=$(df -k "$check_path" 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
    local avail_mb=$((avail_kb / 1024))
    if [[ $avail_mb -lt 512 ]]; then
        error "Less than 512MB disk space available (${avail_mb}MB) on $check_path"
        return 1
    elif [[ $avail_mb -lt 1024 ]]; then
        warn "Low disk space: ${avail_mb}MB available on $check_path"
    else
        ok "Disk space: ${avail_mb}MB available on $check_path"
    fi
}

check_no_conflicting_deploy() {
    log "Checking for conflicting deployments..."
    local deploy_base
    if [[ "$ENVIRONMENT" == "production" ]]; then
        deploy_base=$(get_field "$COL_PROD_BASE")
    else
        deploy_base=$(get_field "$COL_STAGING_BASE")
    fi
    local lock_file="${deploy_base}/.deploy.lock"
    if [[ -f "$lock_file" ]]; then
        local lock_age=$(( $(date +%s) - $(stat -c %Y "$lock_file") ))
        if [[ $lock_age -gt 3600 ]]; then
            warn "Stale lock file found (${lock_age}s old)"
        else
            error "Active deployment lock found (${lock_age}s old)"
            return 1
        fi
    fi
    ok "No conflicting deployments"
}

check_environment_tools() {
    log "Checking required tools..."
    local tools=("git" "rsync" "curl")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            ok "$tool is available"
        else
            warn "$tool is not available"
        fi
    done
}

run_all_checks() {
    echo ""
    echo "========================================"
    echo "  PREFLIGHT CHECKS: $SITE_NAME ($ENVIRONMENT)"
    echo "  COMMIT: $COMMIT"
    echo "========================================"
    echo ""
    ERRORS=0
    WARNINGS=0
    check_registry || true
    check_repo_path || true
    check_deploy_base || true
    check_shared_path || true
    check_commit || true
    check_healthcheck_endpoint || true
    check_port_collision_guard || true
    check_disk_space || true
    check_no_conflicting_deploy || true
    check_environment_tools || true
    echo ""
    echo "========================================"
    echo "  RESULTS: $ERRORS errors, $WARNINGS warnings"
    echo "========================================"
    echo ""
    if [[ $ERRORS -gt 0 ]]; then
        error "Preflight checks FAILED"
        return 1
    fi
    if [[ $WARNINGS -gt 0 ]]; then
        warn "Preflight passed with warnings"
    else
        ok "All preflight checks passed"
    fi
    return 0
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --site)         SITE_NAME="$2"; shift 2 ;;
            --environment)  ENVIRONMENT="$2"; shift 2 ;;
            --commit)       COMMIT="$2"; shift 2 ;;
            --dry-run)      DRY_RUN=true; shift ;;
            --check)        CHECK_MODE=true; shift ;;
            -h|--help)      usage; exit 0 ;;
            *)              error "Unknown option: $1" ;;
        esac
    done
    validate_args || exit 1
    run_all_checks
}

main "$@"
