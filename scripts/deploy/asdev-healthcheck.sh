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
TIMEOUT=10
RETRIES=3
RETRY_DELAY=5

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

Verify deployment health for a site.

Required:
  --site <name>           Site to check (must exist in registry)
  --environment <env>     Target environment: staging|production
  --commit <sha>          Git commit SHA that was deployed

Optional:
  --dry-run               Preview checks without running
  --check                 Run validation only
  --timeout <secs>        Connection timeout (default: 10)
  --retries <n>           Number of retries (default: 3)
  --retry-delay <secs>    Delay between retries (default: 5)
  -h, --help              Show this help

Examples:
  $(basename "$0") --site auditsystems --environment staging --commit abc1234
  $(basename "$0") --site persiantoolbox --environment production --commit def5678 --dry-run
EOF
}

log()   { echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"; }
warn()  { echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR:${NC} $1" >&2; return 1; }
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

check_http() {
    local url="$1" label="$2"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would check: $label ($url)"
        return 0
    fi
    log "Checking: $label"
    local attempt=1 http_code
    while [[ $attempt -le $RETRIES ]]; do
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT" "$url" 2>/dev/null || echo "000")
        if [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then
            ok "$label: HTTP $http_code"
            return 0
        fi
        if [[ $attempt -lt $RETRIES ]]; then
            log "Attempt $attempt failed, retrying in ${RETRY_DELAY}s..."
            sleep "$RETRY_DELAY"
        fi
        ((attempt++)) || true
    done
    error "$label: Failed after $RETRIES attempts (last HTTP $http_code)"
    return 1
}

check_process_running() {
    local process_names="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would check processes: $process_names"
        return 0
    fi
    log "Checking processes: $process_names"
    IFS='|' read -ra procs <<< "$process_names"
    local all_ok=true
    for proc in "${procs[@]}"; do
        proc=$(echo "$proc" | xargs)
        if pgrep -f "$proc" >/dev/null 2>&1; then
            ok "Process running: $proc"
        else
            warn "Process not found: $proc"
            all_ok=false
        fi
    done
    if [[ "$all_ok" == "false" ]]; then return 1; fi
    return 0
}

check_symlink() {
    local deploy_base="$1"
    local current_link="${deploy_base}/current"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would verify current symlink"
        return 0
    fi
    if [[ -L "$current_link" ]] && [[ -d "$current_link" ]]; then
        ok "Current symlink valid: $(readlink -f "$current_link")"
        return 0
    else
        error "Current symlink missing or broken"
        return 1
    fi
}

run_healthcheck() {
    echo ""
    echo "========================================"
    echo "  HEALTHCHECK: $SITE_NAME ($ENVIRONMENT)"
    echo "  COMMIT: $COMMIT"
    echo "========================================"
    echo ""
    local hc_mode hc_host_alias hc_port hc_path deploy_base process_names
    hc_mode=$(get_field "$COL_HC_MODE")
    hc_host_alias=$(get_field "$COL_HC_HOST_ALIAS")
    hc_port=$(get_field "$COL_HC_PORT")
    hc_path=$(get_field "$COL_HC_PATH")
    process_names=$(get_field "$COL_PROCESS_NAMES")
    if [[ "$ENVIRONMENT" == "production" ]]; then
        deploy_base=$(get_field "$COL_PROD_BASE")
    else
        deploy_base=$(get_field "$COL_STAGING_BASE")
    fi
    local all_ok=true
    check_symlink "$deploy_base" || all_ok=false
    if [[ -n "$process_names" && "$process_names" != "-" ]]; then
        check_process_running "$process_names" || all_ok=false
    fi
    case "$hc_mode" in
        local-port)
            if [[ -n "$hc_port" && "$hc_port" != "-" ]]; then
                local full_url="http://127.0.0.1:${hc_port}${hc_path}"
                check_http "$full_url" "Health endpoint (local-port)" || all_ok=false
            else
                warn "local-port mode but no healthcheck_port configured — skipping HTTP check"
            fi
            ;;
        public-url)
            if [[ -n "$hc_host_alias" && "$hc_host_alias" != "-" ]]; then
                local full_url="https://${hc_host_alias}${hc_path}"
                check_http "$full_url" "Health endpoint (public-url)" || all_ok=false
            else
                warn "public-url mode but no healthcheck_host_alias configured — skipping HTTP check"
            fi
            ;;
        command)
            warn "Healthcheck mode is 'command' — manual health check required"
            ;;
        none)
            warn "Healthcheck mode is 'none' — skipping health check"
            ;;
        *)
            warn "Unknown healthcheck mode: $hc_mode — skipping HTTP check"
            ;;
    esac
    echo ""
    echo "========================================"
    if [[ "$all_ok" == "true" ]]; then
        ok "All health checks PASSED"
    else
        error "Some health checks FAILED"
    fi
    echo "========================================"
    echo ""
    [[ "$all_ok" == "true" ]]
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --site)         SITE_NAME="$2"; shift 2 ;;
            --environment)  ENVIRONMENT="$2"; shift 2 ;;
            --commit)       COMMIT="$2"; shift 2 ;;
            --dry-run)      DRY_RUN=true; shift ;;
            --check)        CHECK_MODE=true; shift ;;
            --timeout)      TIMEOUT="$2"; shift 2 ;;
            --retries)      RETRIES="$2"; shift 2 ;;
            --retry-delay)  RETRY_DELAY="$2"; shift 2 ;;
            -h|--help)      usage; exit 0 ;;
            *)              error "Unknown option: $1" ;;
        esac
    done
    validate_args || exit 1
    if [[ "$CHECK_MODE" == "true" ]]; then
        log "Check mode — validating healthcheck config for $SITE_NAME"
        local hc_mode hc_port hc_path
        hc_mode=$(get_field "$COL_HC_MODE")
        hc_port=$(get_field "$COL_HC_PORT")
        hc_path=$(get_field "$COL_HC_PATH")
        log "Healthcheck mode: $hc_mode"
        log "Healthcheck port: $hc_port"
        log "Healthcheck path: $hc_path"
        ok "Validation complete — no checks executed"
        exit 0
    fi
    run_healthcheck
}

main "$@"
