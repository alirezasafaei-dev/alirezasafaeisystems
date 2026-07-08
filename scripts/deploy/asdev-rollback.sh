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
TARGET_VERSION=""
DRY_RUN=false
CHECK_MODE=false
APPROVE_PHRASE=""

COL_SITE_ID=1
COL_DISPLAY_NAME=2
COL_PRIORITY=3
COL_PROTECTED=4
COL_REPO_PATH=5
COL_ARTIFACT_PATH=6
COL_PROD_BASE=7
COL_STAGING_BASE=8
COL_SHARED_PATH=9
COL_HC_URL_ALIAS=10
COL_HC_PATH=11
COL_RUNTIME=12
COL_PROCESS_NAMES=13
COL_BUILD_CMD=14
COL_START_CMD=15
COL_ENV_ALIAS=16
COL_DEPLOY_STRATEGY=17
COL_ROLLBACK_STRATEGY=18

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Roll back a site to a previous release via symlink swap.

Required:
  --site <name>              Site to roll back (must exist in registry)
  --environment <env>        Target environment: staging|production
  --commit <sha>             Git commit SHA (for audit trail)

Optional:
  --target-version <id>      Specific release version to roll back to
  --dry-run                  Preview changes without applying
  --check                    Run validation only
  --approve-phrase <phrase>  Approval phrase for gate
  -h, --help                 Show this help

Examples:
  $(basename "$0") --site auditsystems --environment staging --commit abc1234
  $(basename "$0") --site persiantoolbox --environment production --commit def5678 --target-version 20260708T120000Z-abc1234
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

require_approval() {
    local env="$1" protected="$2"
    if [[ "$APPROVE_PHRASE" != "" ]]; then return 0; fi
    if [[ "$env" == "production" ]]; then
        if [[ "$protected" == "true" ]]; then
            error "Production rollback to protected site requires --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
        else
            error "Production rollback requires --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
        fi
    fi
    if [[ "$env" == "staging" ]]; then
        error "Staging rollback requires --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY"
    fi
}

validate_approve_phrase() {
    local env="$1" protected="$2"
    if [[ "$APPROVE_PHRASE" == "" ]]; then
        if [[ "$DRY_RUN" == "false" ]]; then
            warn "No --approve-phrase provided; defaulting to dry-run mode"
            DRY_RUN=true
        fi
        return 0
    fi
    if [[ "$env" == "production" ]]; then
        [[ "$APPROVE_PHRASE" != "APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY" ]] && error "Invalid approval phrase for production. Expected: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
    fi
    if [[ "$env" == "staging" ]]; then
        [[ "$APPROVE_PHRASE" != "APPROVE_PHASE_2_STAGING_DEPLOY" ]] && error "Invalid approval phrase for staging. Expected: APPROVE_PHASE_2_STAGING_DEPLOY"
    fi
}

list_releases() {
    local deploy_base="$1"
    if [[ -d "${deploy_base}/releases" ]]; then
        ls -1dt "${deploy_base}/releases"/*/ 2>/dev/null | xargs -I{} basename {} || true
    fi
}

find_previous_release() {
    local deploy_base="$1"
    local current_link="${deploy_base}/current"
    local current_target=""
    if [[ -L "$current_link" ]]; then
        current_target=$(readlink -f "$current_link")
    fi
    while IFS= read -r release_dir; do
        [[ -z "$release_dir" ]] && continue
        local full_path="${deploy_base}/releases/${release_dir}"
        [[ "$full_path" == "$current_target" ]] && continue
        echo "$release_dir"
        return
    done < <(list_releases "$deploy_base")
}

run_healthcheck_after_rollback() {
    local site="$1" env="$2" commit="$3"
    if [[ -f "$SCRIPT_DIR/asdev-healthcheck.sh" ]]; then
        bash "$SCRIPT_DIR/asdev-healthcheck.sh" --site "$site" --environment "$env" --commit "$commit"
    fi
}

rollback_symlink() {
    local site="$1" environment="$2" commit="$3" target_version="$4"
    local deploy_base
    if [[ "$environment" == "production" ]]; then
        deploy_base=$(get_field "$COL_PROD_BASE")
    else
        deploy_base=$(get_field "$COL_STAGING_BASE")
    fi
    local current_link="${deploy_base}/current"
    local releases_dir="${deploy_base}/releases"
    if [[ -z "$target_version" ]]; then
        target_version=$(find_previous_release "$deploy_base")
        [[ -z "$target_version" ]] && error "No previous release found to roll back to"
    fi
    local target_dir="${releases_dir}/${target_version}"
    [[ ! -d "$target_dir" ]] && error "Target release not found: $target_dir"
    local current_release=""
    if [[ -L "$current_link" ]]; then
        current_release=$(basename "$(readlink -f "$current_link")")
    fi
    log "Rollback: $site ($environment)"
    log "Current: ${current_release:-none}"
    log "Target:  $target_version"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would symlink: $current_link -> $target_dir"
        log "[DRY RUN] Would run healthcheck"
        return 0
    fi
    ln -sfn "$target_dir" "$current_link"
    ok "Symlink updated: $current_link -> $target_dir"
    log "Running post-rollback healthcheck..."
    run_healthcheck_after_rollback "$site" "$environment" "$commit" || {
        warn "Healthcheck after rollback failed — symlink has been swapped; manual intervention may be needed"
    }
    ok "Rollback complete: $site -> $target_version"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --site)            SITE_NAME="$2"; shift 2 ;;
            --environment)     ENVIRONMENT="$2"; shift 2 ;;
            --commit)          COMMIT="$2"; shift 2 ;;
            --target-version)  TARGET_VERSION="$2"; shift 2 ;;
            --dry-run)         DRY_RUN=true; shift ;;
            --check)           CHECK_MODE=true; shift ;;
            --approve-phrase)  APPROVE_PHRASE="$2"; shift 2 ;;
            -h|--help)         usage; exit 0 ;;
            *)                 error "Unknown option: $1" ;;
        esac
    done
    validate_args
    local protected
    protected=$(get_field "$COL_PROTECTED")
    if [[ "$CHECK_MODE" == "true" ]]; then
        log "Check mode — validating rollback config for $SITE_NAME"
        log "Protected: $protected"
        local deploy_base
        if [[ "$ENVIRONMENT" == "production" ]]; then
            deploy_base=$(get_field "$COL_PROD_BASE")
        else
            deploy_base=$(get_field "$COL_STAGING_BASE")
        fi
        log "Available releases:"
        list_releases "$deploy_base" | sed 's/^/  - /' || true
        ok "Validation complete — no changes applied"
        exit 0
    fi
    validate_approve_phrase "$ENVIRONMENT" "$protected"
    require_approval "$ENVIRONMENT" "$protected"
    rollback_symlink "$SITE_NAME" "$ENVIRONMENT" "$COMMIT" "$TARGET_VERSION"
}

main "$@"
