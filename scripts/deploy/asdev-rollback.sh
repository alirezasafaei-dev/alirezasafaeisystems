#!/usr/bin/env bash
set -euo pipefail

# ASDEV Rollback Script
# Rolls back a site to a previous version

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
REGISTRY="$PROJECT_ROOT/deploy/registry.tsv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DRY_RUN=false
SITE_NAME=""
TARGET_VERSION=""
FORCE=false

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <site-name> [target-version]

Roll back a site to a previous version.

Arguments:
    site-name           Site to roll back (must exist in registry)
    target-version      Version to roll back to (optional, defaults to previous version)

Options:
    --dry-run           Preview changes without applying
    --force             Skip confirmation prompts
    -h, --help          Show this help message

Examples:
    $(basename "$0") auditsystems
    $(basename "$0") --dry-run persiantoolbox 20260707-110000-x9y8z7
    $(basename "$0") --force auditsystems
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

get_current_version() {
    local site="$1"
    local deploy_path
    deploy_path=$(get_deploy_path "$site")
    local current_path="${deploy_path}/current"
    
    if [[ -L "$current_path" ]] && [[ -d "$current_path" ]]; then
        basename "$(readlink -f "$current_path")"
    else
        echo ""
    fi
}

get_previous_version() {
    local site="$1"
    local deploy_path
    deploy_path=$(get_deploy_path "$site")
    local metadata_dir="${deploy_path}/.deploy"
    local rollback_info="${metadata_dir}/rollback-info.json"
    
    if [[ -f "$rollback_info" ]]; then
        # Extract previous version from JSON
        grep -o '"previous_version": *"[^"]*"' "$rollback_info" | cut -d'"' -f4
    else
        echo ""
    fi
}

list_available_versions() {
    local site="$1"
    local deploy_path
    deploy_path=$(get_deploy_path "$site")
    local releases_path="${deploy_path}/releases"
    
    if [[ -d "$releases_path" ]]; then
        ls -1 "$releases_path" | sort -r
    else
        echo ""
    fi
}

find_backup_file() {
    local site="$1"
    local version="$2"
    local backup_path
    backup_path=$(get_backup_path "$site")
    
    # Find backup file matching the version
    find "$backup_path" -name "${version}-*.tar.gz" -type f 2>/dev/null | head -1
}

request_approval() {
    local site="$1"
    
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}ROLLBACK CONFIRMATION${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "Site: $site"
    echo "Critical: $(is_critical_site "$site" && echo "Yes" || echo "No")"
    echo ""
    
    if [[ "$FORCE" == "true" ]]; then
        log "Force mode: Skipping confirmation"
        return 0
    fi
    
    read -p "Are you sure you want to roll back this site? (yes/no): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        log "Rollback cancelled by user"
        exit 0
    fi
}

restore_from_backup() {
    local site="$1"
    local version="$2"
    local deploy_path
    local backup_path
    local releases_path
    
    deploy_path=$(get_deploy_path "$site")
    backup_path=$(get_backup_path "$site")
    releases_path="${deploy_path}/releases"
    
    log "Restoring version $version from backup"
    
    # Find backup file
    local backup_file
    backup_file=$(find_backup_file "$site" "$version")
    
    if [[ -z "$backup_file" ]]; then
        error "No backup found for version $version"
    fi
    
    log "Found backup: $backup_file"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would restore from backup: $backup_file"
        log "[DRY RUN] Would update symlink: ${deploy_path}/current -> releases/$version"
        return 0
    fi
    
    # Create releases directory
    mkdir -p "$releases_path"
    
    # Extract backup
    tar -xzf "$backup_file" -C "$releases_path"
    
    # Update symlink
    local release_path="${releases_path}/${version}"
    ln -sfn "$release_path" "${deploy_path}/current"
    
    # Record rollback
    record_rollback "$site" "$version"
    
    success "Version $version restored from backup"
}

restore_from_releases() {
    local site="$1"
    local version="$2"
    local deploy_path
    local releases_path
    
    deploy_path=$(get_deploy_path "$site")
    releases_path="${deploy_path}/releases"
    
    local release_path="${releases_path}/${version}"
    
    if [[ ! -d "$release_path" ]]; then
        error "Version $version not found in releases"
    fi
    
    log "Restoring version $version from releases"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would update symlink: ${deploy_path}/current -> releases/$version"
        return 0
    fi
    
    # Update symlink
    ln -sfn "$release_path" "${deploy_path}/current"
    
    # Record rollback
    record_rollback "$site" "$version"
    
    success "Version $version restored from releases"
}

record_rollback() {
    local site="$1"
    local version="$2"
    local deploy_path
    local metadata_dir
    
    deploy_path=$(get_deploy_path "$site")
    metadata_dir="${deploy_path}/.deploy"
    
    mkdir -p "$metadata_dir"
    
    # Append to deployments log
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ROLLBACK $site to $version by $(whoami)@$(hostname)" >> "${metadata_dir}/deployments.log"
    
    # Update rollback info
    local current_version
    current_version=$(get_current_version "$site")
    
    cat > "${metadata_dir}/rollback-info.json" << EOF
{
    "current_version": "$version",
    "previous_version": "$current_version",
    "rollback_available": true,
    "rollback_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "rollback_by": "$(whoami)@$(hostname)"
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
            --force)
                FORCE=true
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
                elif [[ -z "$TARGET_VERSION" ]]; then
                    TARGET_VERSION="$1"
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
    
    # Get current version
    local current_version
    current_version=$(get_current_version "$SITE_NAME")
    
    if [[ -z "$current_version" ]]; then
        error "No current version found for $SITE_NAME"
    fi
    
    log "Current version: $current_version"
    
    # Determine target version
    if [[ -z "$TARGET_VERSION" ]]; then
        TARGET_VERSION=$(get_previous_version "$SITE_NAME")
        
        if [[ -z "$TARGET_VERSION" ]]; then
            error "No previous version found. Please specify a target version."
        fi
    fi
    
    log "Target version: $TARGET_VERSION"
    
    # List available versions
    log "Available versions:"
    list_available_versions "$SITE_NAME" | sed 's/^/  - /'
    
    # Request approval
    request_approval "$SITE_NAME"
    
    # Try to restore from backup first
    local backup_file
    backup_file=$(find_backup_file "$SITE_NAME" "$TARGET_VERSION")
    
    if [[ -n "$backup_file" ]]; then
        restore_from_backup "$SITE_NAME" "$TARGET_VERSION"
    else
        # Fall back to releases directory
        restore_from_releases "$SITE_NAME" "$TARGET_VERSION"
    fi
    
    # Run health checks
    run_healthcheck "$SITE_NAME" "$TARGET_VERSION"
    
    success "Rollback completed successfully for $SITE_NAME to version $TARGET_VERSION"
}

main "$@"