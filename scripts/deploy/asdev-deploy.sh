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

Deploy a site with change detection and approval gates.

Required:
  --site <name>              Site to deploy (must exist in registry)
  --environment <env>        Target environment: staging|production
  --commit <sha>             Git commit SHA to deploy

Optional:
  --dry-run                  Preview changes without applying
  --check                    Run validation only
  --approve-phrase <phrase>  Approval phrase for gate
  -h, --help                 Show this help

Examples:
  $(basename "$0") --site auditsystems --environment staging --commit abc1234
  $(basename "$0") --site persiantoolbox --environment production --commit def5678 --dry-run
  $(basename "$0") --site auditsystems --environment staging --commit abc1234 --check
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

validate_site() {
    [[ -z "$SITE_NAME" ]] && error "Missing required --site"
    [[ -z "$ENVIRONMENT" ]] && error "Missing required --environment (staging|production)"
    [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]] && error "Invalid environment: $ENVIRONMENT (must be staging or production)"
    [[ -z "$COMMIT" ]] && error "Missing required --commit"
    grep -q "^${SITE_NAME}	" "$REGISTRY" 2>/dev/null || error "Site '$SITE_NAME' not found in registry. Available: $(tail -n +2 "$REGISTRY" | cut -f1 | tr '\n' ' ')"
}

is_protected() {
    local val
    val=$(registry_field "$SITE_NAME" "$COL_PROTECTED")
    [[ "$val" == "true" ]]
}

get_field() {
    registry_field "$SITE_NAME" "$2"
}

require_approval() {
    local env="$1" protected="$2"
    if [[ "$APPROVE_PHRASE" != "" ]]; then return 0; fi
    if [[ "$env" == "production" ]]; then
        if [[ "$protected" == "true" ]]; then
            error "Production deploy to protected site requires --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
        else
            error "Production deploy requires --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
        fi
    fi
    if [[ "$env" == "staging" ]]; then
        error "Staging deploy requires --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY"
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
        if [[ "$APPROVE_PHRASE" != "APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY" ]]; then
            error "Invalid approval phrase for production. Expected: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
        fi
    fi
    if [[ "$env" == "staging" ]]; then
        if [[ "$APPROVE_PHRASE" != "APPROVE_PHASE_2_STAGING_DEPLOY" ]]; then
            error "Invalid approval phrase for staging. Expected: APPROVE_PHASE_2_STAGING_DEPLOY"
        fi
    fi
}

run_build_command_id() {
    local cmd_id="$1"
    case "$cmd_id" in
        node-pnpm-build) pnpm install --frozen-lockfile && pnpm run build ;;
        node-npm-build) npm ci && npm run build ;;
        static-copy) echo "static copy only" ;;
        no-build|-|"") echo "no build configured" ;;
        *) fail "Unknown build_command_id: $cmd_id" ;;
    esac
}

detect_changes() {
    local repo_path="$1" commit="$2"
    local src_dir="${PROJECT_ROOT}/${repo_path}"
    if [[ ! -d "$src_dir" ]]; then
        warn "Repo path not found locally: $src_dir — skipping change detection"
        echo "unknown"
        return
    fi
    if ! git -C "$src_dir" rev-parse --verify "$commit" >/dev/null 2>&1; then
        warn "Commit $commit not found in $src_dir — skipping change detection"
        echo "unknown"
        return
    fi
    local parent
    parent=$(git -C "$src_dir" rev-parse "${commit}^" 2>/dev/null || echo "")
    if [[ -z "$parent" ]]; then
        echo "initial"
        return
    fi
    local changed_files
    changed_files=$(git -C "$src_dir" diff --name-only "$parent" "$commit" 2>/dev/null || echo "")
    if [[ -z "$changed_files" ]]; then
        echo "none"
        return
    fi
    local has_source=false has_config=false has_deps=false has_docs=false
    while IFS= read -r f; do
        case "$f" in
            *.ts|*.tsx|*.js|*.jsx|*.py|*.rb|*.go|src/*|app/*|lib/*) has_source=true ;;
            *.env*|*.json|*.yaml|*.yml|*.toml|config/*) has_config=true ;;
            package.json|pnpm-lock.yaml|yarn.lock|package-lock.json|requirements.txt) has_deps=true ;;
            *.md|*.txt|docs/*) has_docs=true ;;
        esac
    done <<< "$changed_files"
    if [[ "$has_source" == "true" ]]; then echo "source"
    elif [[ "$has_config" == "true" ]]; then echo "config"
    elif [[ "$has_deps" == "true" ]]; then echo "deps"
    elif [[ "$has_docs" == "true" ]]; then echo "docs"
    else echo "other"
    fi
}

deploy_site_artifact() {
    local site="$1" commit="$2" environment="$3"
    local repo_path artifact_path deploy_base shared_path build_cmd_id start_cmd_id env_alias runtime process_names
    repo_path=$(get_field "$site" "$COL_REPO_PATH")
    artifact_path=$(get_field "$site" "$COL_ARTIFACT_PATH")
    if [[ "$environment" == "production" ]]; then
        deploy_base=$(get_field "$site" "$COL_PROD_BASE")
    else
        deploy_base=$(get_field "$site" "$COL_STAGING_BASE")
    fi
    shared_path=$(get_field "$site" "$COL_SHARED_PATH")
    build_cmd_id=$(get_field "$site" "$COL_BUILD_CMD_ID")
    start_cmd_id=$(get_field "$site" "$COL_START_CMD_ID")
    env_alias=$(get_field "$site" "$COL_ENV_ALIAS")
    runtime=$(get_field "$site" "$COL_RUNTIME")
    process_names=$(get_field "$site" "$COL_PROCESS_NAMES")

    local src_dir="${PROJECT_ROOT}/${repo_path}"
    local release_id
    release_id="$(date -u +%Y%m%dT%H%M%SZ)-${commit:0:7}"
    local release_dir="${deploy_base}/releases/${release_id}"
    local current_link="${deploy_base}/current"

    log "Site: $site | Environment: $environment | Commit: $commit"
    log "Release: $release_id"
    log "Deploy base: $deploy_base"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would create release dir: $release_dir"
        log "[DRY RUN] Would sync site-scoped source from: $src_dir"
        log "[DRY RUN] Would run build_command_id: $build_cmd_id"
        log "[DRY RUN] Would symlink current -> $release_dir"
        log "[DRY RUN] Would run post-activation healthcheck"
        log "[DRY RUN] Would rollback symlink if healthcheck fails"
        return 0
    fi

    mkdir -p "$deploy_base/releases" "$shared_path"

    if [[ -d "$src_dir" ]]; then
        mkdir -p "$release_dir"
        rsync -a --delete \
            --exclude '.git' \
            --exclude 'node_modules' \
            --exclude '.next' \
            --exclude 'coverage' \
            --exclude 'artifacts' \
            --exclude 'test-results' \
            "$src_dir/" "$release_dir/"
    elif [[ -d "${PROJECT_ROOT}/${artifact_path}" ]]; then
        mkdir -p "$release_dir"
        rsync -a --delete "${PROJECT_ROOT}/${artifact_path}/" "$release_dir/"
    else
        error "No source or artifact found for $site"
    fi

    if [[ -n "$build_cmd_id" && "$build_cmd_id" != "-" ]]; then
        log "Running build_command_id: $build_cmd_id"
        (cd "$release_dir" && run_build_command_id "$build_cmd_id")
    fi

    ln -sfn "$release_dir" "$current_link"
    log "Symlink switched: $current_link -> $release_dir"

    local hc_mode hc_port hc_path
    hc_mode=$(get_field "$site" "$COL_HC_MODE")
    hc_port=$(get_field "$site" "$COL_HC_PORT")
    hc_path=$(get_field "$site" "$COL_HC_PATH")
    if [[ "$hc_mode" == "local-port" && -n "$hc_port" && "$hc_port" != "-" ]]; then
        log "Running post-activation healthcheck: http://127.0.0.1:${hc_port}${hc_path}"
        local hc_ok=false
        for attempt in $(seq 1 20); do
            if curl -fsS --connect-timeout 5 "http://127.0.0.1:${hc_port}${hc_path}" >/dev/null 2>&1; then
                hc_ok=true
                break
            fi
            sleep 2
        done
        if [[ "$hc_ok" == "false" ]]; then
            warn "Post-activation healthcheck failed for $site — rolling back symlink"
            local previous_release
            previous_release=$(find "${deploy_base}/releases" -maxdepth 1 -mindepth 1 -type d ! -name "$release_id" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}' || true)
            if [[ -n "$previous_release" ]] && [[ -d "$previous_release" ]]; then
                ln -sfn "$previous_release" "$current_link"
                ok "Rolled back symlink to $previous_release"
            else
                warn "No previous release found for rollback — symlink left pointing to failed release"
            fi
            error "Post-activation healthcheck failed for $site at port $hc_port"
        fi
    else
        warn "No local-port healthcheck configured — skipping healthcheck"
    fi
    ok "Deployed $site $release_id (post-activation healthcheck passed)"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --site)           SITE_NAME="$2"; shift 2 ;;
            --environment)    ENVIRONMENT="$2"; shift 2 ;;
            --commit)         COMMIT="$2"; shift 2 ;;
            --dry-run)        DRY_RUN=true; shift ;;
            --check)          CHECK_MODE=true; shift ;;
            --approve-phrase) APPROVE_PHRASE="$2"; shift 2 ;;
            -h|--help)        usage; exit 0 ;;
            *)                error "Unknown option: $1" ;;
        esac
    done

    validate_site

    local protected
    protected=$(get_field "$SITE_NAME" "$COL_PROTECTED")

    if [[ "$CHECK_MODE" == "true" ]]; then
        log "Check mode — validating $SITE_NAME ($ENVIRONMENT, commit $COMMIT)"
        local change_type
        change_type=$(detect_changes "$(get_field "$SITE_NAME" "$COL_REPO_PATH")" "$COMMIT")
        log "Change type: $change_type"
        log "Protected: $protected"
        ok "Validation complete — no changes applied"
        exit 0
    fi

    validate_approve_phrase "$ENVIRONMENT" "$protected"
    require_approval "$ENVIRONMENT" "$protected"

    local change_type
    change_type=$(detect_changes "$(get_field "$SITE_NAME" "$COL_REPO_PATH")" "$COMMIT")
    log "Change type: $change_type"

    deploy_site_artifact "$SITE_NAME" "$COMMIT" "$ENVIRONMENT"
}

main "$@"
