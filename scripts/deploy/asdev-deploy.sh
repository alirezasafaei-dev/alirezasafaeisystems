#!/usr/bin/env bash
set -euo pipefail

# ASDEV Deploy Script
# Deploys a site with change detection and approval gates

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
REGISTRY="$PROJECT_ROOT/deploy/registry.tsv"
TEMPLATES_DIR="$PROJECT_ROOT/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DRY_RUN=false
CHECK_MODE=false
HEALTHCHECK_ONLY=false
SITE_NAME=""
VERSION=""
CHANGES_DIR=""

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <site-name> [version]

Deploy a site with change detection.

Arguments:
    site-name       Site to deploy (must exist in registry)
    version         Version to deploy (optional, defaults to latest)

Options:
    --dry-run       Preview changes without applying
    --check         Run validation only
    --healthcheck-only  Run health checks only
    -h, --help      Show this help message

Examples:
    $(basename "$0") auditsystems
    $(basename "$0") --dry-run persiantoolbox 20260708-125200-a1b2c3d
    $(basename "$0") --check auditsystems
EOF
}

log() {
    echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR:${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SUCCESS:${NC} $1"
}

validate_site_exists() {
    local site="$1"
    if ! grep -q "^${site}" "$REGISTRY"; then
        error "Site '$site' not found in registry. Available sites:"
        tail -n +2 "$REGISTRY" | cut -f1 | sed 's/^/  - /'
    fi
}

get_site_info() {
    local site="$1"
    grep "^${site}" "$REGISTRY" | head -1
}

is_critical_site() {
    local site="$1"
    local site_info
    site_info=$(get_site_info "$site")
    echo "$site_info" | cut -f3 | grep -q "^critical$"
}

get_deploy_path() {
    local site="$1"
    local site_info
    site_info=$(get_site_info "$site")
    echo "$site_info" | cut -f4
}

get_backup_path() {
    local site="$1"
    local site_info
    site_info=$(get_site_info "$site")
    echo "$site_info" | cut -f5
}

generate_version() {
    local short_hash
    short_hash=$(git -C "$PROJECT_ROOT" rev-parse --short=7 HEAD 2>/dev/null || echo "unknown")
    echo "$(date -u +%Y%m%d-%H%M%S)-${short_hash}"
}

detect_changes() {
    local site="$1"
    local deploy_path
    deploy_path=$(get_deploy_path "$site")
    local current_path="${deploy_path}/current"
    
    # Initialize change categories
    local docs_changes=()
    local assets_changes=()
    local deps_changes=()
    local source_changes=()
    local config_changes=()
    local migration_changes=()
    
    # If current version exists, compare with it
    if [[ -L "$current_path" ]] && [[ -d "$current_path" ]]; then
        log "Comparing with current version..."
        
        # Use git diff if available, otherwise use file comparison
        if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
            # Get changed files from git
            while IFS= read -r file; do
                case "$file" in
                    *.md|*.txt|docs/*)
                        docs_changes+=("$file")
                        ;;
                    *.css|*.js|*.html|*.png|*.jpg|*.gif|*.svg|*.ico|public/*)
                        assets_changes+=("$file")
                        ;;
                    package.json|requirements.txt|composer.json|Gemfile|deps/*)
                        deps_changes+=("$file")
                        ;;
                    *.ts|*.js|*.py|*.rb|*.go|src/*|app/*|lib/*)
                        source_changes+=("$file")
                        ;;
                    *.env|*.json|*.yaml|*.yml|*.toml|config/*)
                        config_changes+=("$file")
                        ;;
                    migrations/*|*.sql|schema/*)
                        migration_changes+=("$file")
                        ;;
                esac
            done < <(git -C "$PROJECT_ROOT" diff --name-only HEAD~1 HEAD 2>/dev/null || echo "")
        fi
    fi
    
    # Output change manifest
    cat << EOF
{
    "docs": [$(printf '"%s",' "${docs_changes[@]}" 2>/dev/null | sed 's/,$//')],
    "assets": [$(printf '"%s",' "${assets_changes[@]}" 2>/dev/null | sed 's/,$//')],
    "deps": [$(printf '"%s",' "${deps_changes[@]}" 2>/dev/null | sed 's/,$//')],
    "source": [$(printf '"%s",' "${source_changes[@]}" 2>/dev/null | sed 's/,$//')],
    "config": [$(printf '"%s",' "${config_changes[@]}" 2>/dev/null | sed 's/,$//')],
    "migration": [$(printf '"%s",' "${migration_changes[@]}" 2>/dev/null | sed 's/,$//')]
}
EOF
}

calculate_impact() {
    local manifest="$1"
    
    # Check for critical changes
    if echo "$manifest" | grep -q '"migration":\s*\[[^]]\+'; then
        echo "critical"
    elif echo "$manifest" | grep -q '"source":\s*\[[^]]\+'; then
        echo "high"
    elif echo "$manifest" | grep -q '"config":\s*\[[^]]\+'; then
        echo "high"
    elif echo "$manifest" | grep -q '"deps":\s*\[[^]]\+'; then
        echo "medium"
    else
        echo "low"
    fi
}

requires_approval() {
    local site="$1"
    local impact="$2"
    
    # Critical site always requires approval for production
    if is_critical_site "$site"; then
        return 0
    fi
    
    # High or critical impact requires approval
    if [[ "$impact" == "high" ]] || [[ "$impact" == "critical" ]]; then
        return 0
    fi
    
    return 1
}

request_approval() {
    local site="$1"
    local impact="$2"
    
    if ! requires_approval "$site" "$impact"; then
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}APPROVAL REQUIRED${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "Site: $site"
    echo "Impact: $impact"
    echo "Critical: $(is_critical_site "$site" && echo "Yes" || echo "No")"
    echo ""
    
    if is_critical_site "$site"; then
        echo "This is a critical site deployment."
        echo "Required approval phrase: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
    else
        echo "This deployment has $impact impact."
        echo "Required approval phrase: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
    fi
    
    echo ""
    read -p "Enter approval phrase: " approval_phrase
    
    if [[ "$approval_phrase" != "APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY" ]]; then
        error "Invalid approval phrase. Deployment cancelled."
    fi
    
    success "Approval confirmed."
}

create_backup() {
    local site="$1"
    local version="$2"
    local deploy_path
    local backup_path
    local current_path
    
    deploy_path=$(get_deploy_path "$site")
    backup_path=$(get_backup_path "$site")
    current_path="${deploy_path}/current"
    
    if [[ ! -L "$current_path" ]]; then
        warn "No current version to backup"
        return 0
    fi
    
    local current_version
    current_version=$(basename "$(readlink -f "$current_path")")
    local backup_file="${backup_path}/${current_version}-$(date -u +%Y%m%d-%H%M%S).tar.gz"
    
    log "Creating backup of current version: $current_version"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would create backup: $backup_file"
        return 0
    fi
    
    mkdir -p "$backup_path"
    tar -czf "$backup_file" -C "$deploy_path" "releases/${current_version}"
    
    # Create metadata file
    cat > "${backup_file}.meta" << EOF
{
    "site": "$site",
    "version": "$current_version",
    "backup_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "backup_file": "$(basename "$backup_file")"
}
EOF
    
    success "Backup created: $backup_file"
}

deploy_version() {
    local site="$1"
    local version="$2"
    local deploy_path
    local releases_path
    local current_path
    
    deploy_path=$(get_deploy_path "$site")
    releases_path="${deploy_path}/releases"
    current_path="${deploy_path}/current"
    
    log "Deploying version $version to $site"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would deploy version $version"
        log "[DRY RUN] Would update symlink: $current_path -> releases/$version"
        return 0
    fi
    
    # Create releases directory
    mkdir -p "$releases_path"
    
    # Copy project to release directory
    local release_path="${releases_path}/${version}"
    mkdir -p "$release_path"
    
    # Copy project files (excluding .git and deploy metadata)
    rsync -av --exclude='.git' --exclude='.deploy' --exclude='deploy' "$PROJECT_ROOT/" "$release_path/"
    
    # Create release metadata
    cat > "${release_path}/.release-meta" << EOF
{
    "version": "$version",
    "deployed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "deployed_by": "$(whoami)@$(hostname)",
    "git_commit": "$(git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")",
    "git_branch": "$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")",
    "change_manifest": $(cat "${CHANGES_DIR}/manifest.json")
}
EOF
    
    # Update symlink
    ln -sfn "$release_path" "$current_path"
    
    # Record deployment
    record_deployment "$site" "$version"
    
    success "Version $version deployed to $site"
}

record_deployment() {
    local site="$1"
    local version="$2"
    local deploy_path
    local metadata_dir
    
    deploy_path=$(get_deploy_path "$site")
    metadata_dir="${deploy_path}/.deploy"
    
    mkdir -p "$metadata_dir"
    
    # Append to deployments log
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] DEPLOY $site $version by $(whoami)@$(hostname)" >> "${metadata_dir}/deployments.log"
    
    # Save current manifest
    cp "${CHANGES_DIR}/manifest.json" "${metadata_dir}/current-manifest.json"
    
    # Update rollback info
    local previous_version=""
    if [[ -L "${deploy_path}/current" ]]; then
        previous_version=$(basename "$(readlink -f "${deploy_path}/current")")
    fi
    
    cat > "${metadata_dir}/rollback-info.json" << EOF
{
    "current_version": "$version",
    "previous_version": "$previous_version",
    "rollback_available": ${previous_version:+true}${previous_version:-false},
    "rollback_path": "${previous_version:+$(get_backup_path "$site")/${previous_version}-*.tar.gz}"
}
EOF
}

run_healthcheck() {
    local site="$1"
    local version="$2"
    
    log "Running health checks for $site version $version"
    
    # Use the healthcheck script if it exists
    if [[ -f "$SCRIPT_DIR/asdev-healthcheck.sh" ]]; then
        bash "$SCRIPT_DIR/asdev-healthcheck.sh" --site "$site" --version "$version"
    else
        warn "Healthcheck script not found, skipping health checks"
    fi
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --check)
                CHECK_MODE=true
                shift
                ;;
            --healthcheck-only)
                HEALTHCHECK_ONLY=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                if [[ -z "$SITE_NAME" ]]; then
                    SITE_NAME="$1"
                elif [[ -z "$VERSION" ]]; then
                    VERSION="$1"
                else
                    error "Too many arguments"
                fi
                shift
                ;;
        esac
    done
    
    # Validate arguments
    if [[ -z "$SITE_NAME" ]]; then
        error "Site name is required"
    fi
    
    # Validate site exists
    validate_site_exists "$SITE_NAME"
    
    # Generate version if not provided
    if [[ -z "$VERSION" ]]; then
        VERSION=$(generate_version)
    fi
    
    # Create temporary directory for changes
    CHANGES_DIR=$(mktemp -d)
    trap 'rm -rf "$CHANGES_DIR"' EXIT
    
    log "Deployment started for $SITE_NAME version $VERSION"
    log "Dry run: $DRY_RUN"
    
    # Detect changes
    log "Detecting changes..."
    detect_changes "$SITE_NAME" > "${CHANGES_DIR}/manifest.json"
    
    # Calculate impact
    local impact
    impact=$(calculate_impact "$(cat "${CHANGES_DIR}/manifest.json")")
    log "Impact level: $impact"
    
    # Check mode only
    if [[ "$CHECK_MODE" == "true" ]]; then
        log "Check mode: Validation complete"
        cat "${CHANGES_DIR}/manifest.json"
        exit 0
    fi
    
    # Healthcheck only mode
    if [[ "$HEALTHCHECK_ONLY" == "true" ]]; then
        run_healthcheck "$SITE_NAME" "$VERSION"
        exit 0
    fi
    
    # Request approval if required
    request_approval "$SITE_NAME" "$impact"
    
    # Create backup
    create_backup "$SITE_NAME" "$VERSION"
    
    # Deploy version
    deploy_version "$SITE_NAME" "$VERSION"
    
    # Run health checks
    run_healthcheck "$SITE_NAME" "$VERSION"
    
    success "Deployment completed successfully for $SITE_NAME version $VERSION"
}

main "$@"