#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/asdev-common.sh
source "${SCRIPT_DIR}/lib/asdev-common.sh"
PROJECT_ROOT="$(asdev_project_root_from "$SCRIPT_DIR")"
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
  --dry-run                  Preview changes without applying. Requires no approval phrase.
  --check                    Run validation only. Requires no approval phrase.
  --approve-phrase <phrase>  Required for live staging/production execution
  -h, --help                 Show this help

Examples:
  $(basename "$0") --site auditsystems --environment staging --commit abc1234 --dry-run
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

validate_approve_phrase() {
    local env="$1"

    # Dry-run and check mode must always be approval-free.
    if [[ "$DRY_RUN" == "true" || "$CHECK_MODE" == "true" ]]; then
        return 0
    fi

    if [[ -z "$APPROVE_PHRASE" ]]; then
        error "Live $env deploy requires --approve-phrase. Use --dry-run or --check for approval-free validation."
    fi

    if [[ "$env" == "production" ]]; then
        if [[ "$APPROVE_PHRASE" != "APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY" ]]; then
            error "Invalid approval phrase for production. Expected: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
        fi
    elif [[ "$env" == "staging" ]]; then
        if [[ "$APPROVE_PHRASE" != "APPROVE_PHASE_2_STAGING_DEPLOY" ]]; then
            error "Invalid approval phrase for staging. Expected: APPROVE_PHASE_2_STAGING_DEPLOY"
        fi
    fi
}

run_build_command_id() {
    local cmd_id="$1"
    # Avoid husky/git hooks in release trees; allow larger heap on small hosts.
    export HUSKY="${HUSKY:-0}"
    export NEXT_TELEMETRY_DISABLED="${NEXT_TELEMETRY_DISABLED:-1}"
    if [[ -z "${NODE_OPTIONS:-}" ]]; then
        export NODE_OPTIONS="--max-old-space-size=3072"
    fi
    case "$cmd_id" in
        node-pnpm-build)
            # Full deps needed for Next build; ignore lifecycle scripts then run build.
            pnpm install --frozen-lockfile --ignore-scripts
            pnpm run build
            ;;
        node-npm-build) npm ci --ignore-scripts && npm run build ;;
        static-copy) echo "static copy only" ;;
        no-build|-|"") echo "no build configured" ;;
        *) error "Unknown build_command_id: $cmd_id" ;;
    esac
}

detect_changes() {
    local site="$1" repo_path="$2" commit="$3"
    local src_dir
    src_dir="$(asdev_resolve_site_src "$PROJECT_ROOT" "$site" "$repo_path")"
    if [[ ! -d "$src_dir" ]]; then
        warn "Repo path not found locally: $src_dir — skipping change detection"
        echo "unknown"
        return
    fi
    # Mother-repo site may use ASDEV commit; external site may not contain it.
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

    local src_dir
    src_dir="$(asdev_resolve_site_src "$PROJECT_ROOT" "$site" "$repo_path")"
    local src_status
    src_status="$(asdev_site_src_status "$src_dir")"
    local release_id
    release_id="$(date -u +%Y%m%dT%H%M%SZ)-${commit:0:7}"
    local release_dir="${deploy_base}/releases/${release_id}"
    local current_link="${deploy_base}/current"
    local previous_pointer="${deploy_base}/previous-release"
    local current_release=""
    if [[ -L "$current_link" ]]; then
        current_release=$(basename "$(readlink -f "$current_link" 2>/dev/null || true)" 2>/dev/null || true)
    fi

    log "Site: $site | Environment: $environment | Commit: $commit"
    log "Release: $release_id"
    log "Deploy base: $deploy_base"
    log "Source: $src_dir (status=$src_status)"
    log "Previous release: ${current_release:-none}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would create release dir: $release_dir"
        log "[DRY RUN] Would write release metadata (release.meta)"
        log "[DRY RUN] Would sync site-scoped source from: $src_dir"
        if [[ "$src_status" != "ready" ]]; then
            warn "[DRY RUN] Source not ready — run: scripts/deploy/asdev-prepare-site-source.sh --site $site --apply"
        fi
        log "[DRY RUN] Would run build_command_id: $build_cmd_id"
        if [[ -n "$current_release" ]]; then
            log "[DRY RUN] Would record previous-release pointer: $current_release"
        fi
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
        error "No source or artifact found for $site (tried $src_dir). Run asdev-prepare-site-source.sh --site $site --apply"
    fi

    # Release metadata for audit trail and safer rollback selection.
    cat > "${release_dir}/release.meta" <<EOF
site=${site}
environment=${environment}
commit=${commit}
release_id=${release_id}
created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
runtime=${runtime}
build_command_id=${build_cmd_id}
start_command_id=${start_cmd_id}
previous_release=${current_release:-}
EOF

    if [[ -n "$build_cmd_id" && "$build_cmd_id" != "-" ]]; then
        log "Running build_command_id: $build_cmd_id"
        (cd "$release_dir" && run_build_command_id "$build_cmd_id")
    fi

    # Record previous release before symlink switch.
    if [[ -n "$current_release" ]]; then
        printf '%s\n' "$current_release" > "$previous_pointer"
        log "Recorded previous-release: $current_release"
    fi

    ln -sfn "$release_dir" "$current_link"
    log "Symlink switched: $current_link -> $release_dir"

    local hc_mode hc_port hc_path
    hc_mode=$(get_field "$site" "$COL_HC_MODE")
    hc_port=$(get_field "$site" "$COL_HC_PORT")
    hc_path=$(get_field "$site" "$COL_HC_PATH")

    # Start runtime after activation (required for post-activation healthcheck).
    start_runtime "$site" "$environment" "$deploy_base" "$release_dir" "$start_cmd_id" "$hc_port" "$process_names"

    if [[ "$hc_mode" == "local-port" && -n "$hc_port" && "$hc_port" != "-" ]]; then
        log "Running post-activation healthcheck: http://127.0.0.1:${hc_port}${hc_path}"
        local hc_ok=false
        for attempt in $(seq 1 30); do
            if curl -fsS --connect-timeout 5 "http://127.0.0.1:${hc_port}${hc_path}" >/dev/null 2>&1; then
                hc_ok=true
                break
            fi
            sleep 2
        done
        if [[ "$hc_ok" == "false" ]]; then
            warn "Post-activation healthcheck failed for $site — rolling back symlink"
            stop_runtime "$deploy_base"
            local previous_release=""
            if [[ -f "$previous_pointer" ]]; then
                previous_release=$(tr -d '[:space:]' < "$previous_pointer")
            fi
            if [[ -z "$previous_release" ]]; then
                previous_release=$(find "${deploy_base}/releases" -maxdepth 1 -mindepth 1 -type d ! -name "$release_id" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}' || true)
                previous_release=$(basename "${previous_release:-}")
            fi
            local previous_dir="${deploy_base}/releases/${previous_release}"
            if [[ -n "$previous_release" && -d "$previous_dir" ]]; then
                ln -sfn "$previous_dir" "$current_link"
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

stop_runtime() {
    local deploy_base="$1"
    local pid_file="${deploy_base}/asdev-runtime.pid"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(tr -d '[:space:]' < "$pid_file" || true)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            sleep 1
            kill -9 "$pid" 2>/dev/null || true
            log "Stopped runtime pid $pid"
        fi
        rm -f "$pid_file"
    fi
}

start_runtime() {
    local site="$1" environment="$2" deploy_base="$3" release_dir="$4" start_cmd_id="$5" hc_port="$6" process_names="$7"
    local pid_file="${deploy_base}/asdev-runtime.pid"
    local log_file="${deploy_base}/asdev-runtime.log"

    case "$start_cmd_id" in
        node-standalone|"")
            ;;
        *)
            warn "Unknown start_command_id '$start_cmd_id' — skipping runtime start"
            return 0
            ;;
    esac

    stop_runtime "$deploy_base"

    local server_js=""
    if [[ -f "${release_dir}/.next/standalone/server.js" ]]; then
        server_js="${release_dir}/.next/standalone/server.js"
        # Next standalone expects static/public alongside server bundle.
        mkdir -p "${release_dir}/.next/standalone/.next"
        if [[ -d "${release_dir}/.next/static" ]]; then
            rm -rf "${release_dir}/.next/standalone/.next/static"
            cp -a "${release_dir}/.next/static" "${release_dir}/.next/standalone/.next/static"
        fi
        if [[ -d "${release_dir}/public" ]]; then
            rm -rf "${release_dir}/.next/standalone/public"
            cp -a "${release_dir}/public" "${release_dir}/.next/standalone/public"
        fi
    elif [[ -f "${release_dir}/server.js" ]]; then
        server_js="${release_dir}/server.js"
    else
        warn "No standalone server.js found under $release_dir — healthcheck may fail"
        return 0
    fi

    local port="${hc_port:-3000}"
    log "Starting node-standalone for $site ($environment) on 127.0.0.1:${port}"
    (
        cd "$(dirname "$server_js")"
        export PORT="$port"
        export HOSTNAME="127.0.0.1"
        export NODE_ENV="production"
        nohup node "$(basename "$server_js")" >>"$log_file" 2>&1 &
        echo $! >"$pid_file"
    )
    sleep 2
    if [[ -f "$pid_file" ]] && kill -0 "$(tr -d '[:space:]' < "$pid_file")" 2>/dev/null; then
        ok "Runtime started pid=$(tr -d '[:space:]' < "$pid_file") process_hint=${process_names:-$site}"
    else
        warn "Runtime pid not active after start — see $log_file"
    fi
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
        local change_type repo_path src_dir src_status
        repo_path=$(get_field "$SITE_NAME" "$COL_REPO_PATH")
        src_dir="$(asdev_resolve_site_src "$PROJECT_ROOT" "$SITE_NAME" "$repo_path")"
        src_status="$(asdev_site_src_status "$src_dir")"
        change_type=$(detect_changes "$SITE_NAME" "$repo_path" "$COMMIT")
        log "Source: $src_dir (status=$src_status)"
        log "Change type: $change_type"
        log "Protected: $protected"
        ok "Validation complete — no changes applied"
        exit 0
    fi

    validate_approve_phrase "$ENVIRONMENT" "$protected"

    local change_type
    change_type=$(detect_changes "$SITE_NAME" "$(get_field "$SITE_NAME" "$COL_REPO_PATH")" "$COMMIT")
    log "Change type: $change_type"

    deploy_site_artifact "$SITE_NAME" "$COMMIT" "$ENVIRONMENT"
}

main "$@"
