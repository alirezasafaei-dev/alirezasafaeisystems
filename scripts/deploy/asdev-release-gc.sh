#!/usr/bin/env bash
set -euo pipefail

# ASDEV Release Garbage Collection Script
# Manages release retention and cleanup

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
FORCE=false
QUARANTINE_DAYS=7
KEEP_RELEASES=5
BACKUP_RETENTION_DAYS=30

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <site-name>

Manage release garbage collection.

Arguments:
    site-name       Site to manage (must exist in registry)

Options:
    --dry-run           Preview changes without applying
    --force             Skip confirmation prompts
    --quarantine-days   Days before quarantining releases (default: 7)
    --keep-releases     Number of releases to keep (default: 5)
    --backup-retention  Days to keep backups (default: 30)
    -h, --help          Show this help message

Examples:
    $(basename "$0") auditsystems
    $(basename "$0") --dry-run persiantoolbox
    $(basename "$0") --force --keep-releases 3 auditsystems
EOF
}

log() {
    echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR:${NC} $1"
    return 1
}

success() {
    echo -e "${GREEN}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SUCCESS:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] INFO:${NC} $1"
}

validate_site_exists() {
    local site="$1"
    if ! grep -q "^${site}" "$REGISTRY"; then
        error "Site '$site' not found in registry. Available sites:"
        tail -n +2 "$REGISTRY" | cut -f1 | sed 's/^/  - /'
        return 1
    fi
    return 0
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

list_releases() {
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

list_backups() {
    local site="$1"
    local backup_path
    backup_path=$(get_backup_path "$site")
    
    if [[ -d "$backup_path" ]]; then
        find "$backup_path" -name "*.tar.gz" -type f | sort -r
    else
        echo ""
    fi
}

quarantine_release() {
    local site="$1"
    local version="$2"
    local deploy_path
    local releases_path
    local quarantine_path
    
    deploy_path=$(get_deploy_path "$site")
    releases_path="${deploy_path}/releases"
    quarantine_path="${deploy_path}/.quarantine"
    
    local release_path="${releases_path}/${version}"
    
    if [[ ! -d "$release_path" ]]; then
        warn "Release $version not found"
        return 1
    fi
    
    log "Quarantining release: $version"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would quarantine release: $version"
        return 0
    fi
    
    # Create quarantine directory
    mkdir -p "$quarantine_path"
    
    # Move release to quarantine
    mv "$release_path" "${quarantine_path}/${version}"
    
    # Record quarantine
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] QUARANTINE $site $version" >> "${deploy_path}/.deploy/deployments.log"
    
    success "Release $version quarantined"
    return 0
}

delete_release() {
    local site="$1"
    local version="$2"
    local deploy_path
    local releases_path
    
    deploy_path=$(get_deploy_path "$site")
    releases_path="${deploy_path}/releases"
    
    local release_path="${releases_path}/${version}"
    
    if [[ ! -d "$release_path" ]]; then
        warn "Release $version not found"
        return 1
    fi
    
    log "Deleting release: $version"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would delete release: $version"
        return 0
    fi
    
    # Delete release
    rm -rf "$release_path"
    
    # Record deletion
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] DELETE $site $version" >> "${deploy_path}/.deploy/deployments.log"
    
    success "Release $version deleted"
    return 0
}

delete_quarantined_release() {
    local site="$1"
    local version="$2"
    local deploy_path
    local quarantine_path
    
    deploy_path=$(get_deploy_path "$site")
    quarantine_path="${deploy_path}/.quarantine"
    
    local quarantine_release_path="${quarantine_path}/${version}"
    
    if [[ ! -d "$quarantine_release_path" ]]; then
        warn "Quarantined release $version not found"
        return 1
    fi
    
    # Check if site is critical
    if is_critical_site "$site"; then
        error "Cannot delete quarantined release from critical site"
        return 1
    fi
    
    log "Deleting quarantined release: $version"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would delete quarantined release: $version"
        return 0
    fi
    
    # Delete quarantined release
    rm -rf "$quarantine_release_path"
    
    # Record deletion
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] DELETE_QUARANTINED $site $version" >> "${deploy_path}/.deploy/deployments.log"
    
    success "Quarantined release $version deleted"
    return 0
}

delete_old_backup() {
    local backup_file="$1"
    local backup_path
    backup_path=$(dirname "$backup_file")
    
    log "Deleting old backup: $(basename "$backup_file")"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would delete backup: $(basename "$backup_file")"
        return 0
    fi
    
    # Delete backup and metadata
    rm -f "$backup_file"
    rm -f "${backup_file}.meta"
    
    success "Backup deleted: $(basename "$backup_file")"
    return 0
}

request_approval() {
    local site="$1"
    local action="$2"
    
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}APPROVAL REQUIRED${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "Site: $site"
    echo "Action: $action"
    echo "Critical: $(is_critical_site "$site" && echo "Yes" || echo "No")"
    echo ""
    
    if [[ "$FORCE" == "true" ]]; then
        log "Force mode: Skipping approval"
        return 0
    fi
    
    local approval_phrase=""
    
    if [[ "$action" == "delete_quarantined" ]]; then
        echo "Required approval phrase: APPROVE_IRAN_PROD_DELETE_QUARANTINED_NON_CRITICAL"
        read -p "Enter approval phrase: " approval_phrase
        
        if [[ "$approval_phrase" != "APPROVE_IRAN_PROD_DELETE_QUARANTINED_NON_CRITICAL" ]]; then
            error "Invalid approval phrase. Action cancelled."
            return 1
        fi
    else
        read -p "Are you sure you want to $action? (yes/no): " confirmation
        if [[ "$confirmation" != "yes" ]]; then
            log "Action cancelled by user"
            exit 0
        fi
    fi
    
    success "Approval confirmed."
    return 0
}

cleanup_old_releases() {
    local site="$1"
    local current_version
    current_version=$(get_current_version "$site")
    
    log "Cleaning up old releases for $site"
    
    # Get all releases
    local releases
    releases=$(list_releases "$site")
    
    if [[ -z "$releases" ]]; then
        info "No releases found"
        return 0
    fi
    
    # Count releases
    local release_count
    release_count=$(echo "$releases" | wc -l)
    
    info "Found $release_count releases"
    
    # Keep current version and specified number of releases
    local keep_count=$((KEEP_RELEASES + 1))  # +1 for current version
    
    if [[ $release_count -le $keep_count ]]; then
        info "No releases to quarantine (keeping $KEEP_RELEASES + current)"
        return 0
    fi
    
    # Get releases to quarantine
    local releases_to_quarantine
    releases_to_quarantine=$(echo "$releases" | tail -n +$((keep_count + 1)))
    
    # Quarantine old releases
    while IFS= read -r version; do
        if [[ -n "$version" ]] && [[ "$version" != "$current_version" ]]; then
            quarantine_release "$site" "$version"
        fi
    done <<< "$releases_to_quarantine"
}

cleanup_quarantined_releases() {
    local site="$1"
    local deploy_path
    local quarantine_path
    
    deploy_path=$(get_deploy_path "$site")
    quarantine_path="${deploy_path}/.quarantine"
    
    if [[ ! -d "$quarantine_path" ]]; then
        info "No quarantined releases"
        return 0
    fi
    
    log "Checking quarantined releases for $site"
    
    # Get quarantined releases
    local quarantined_releases
    quarantined_releases=$(ls -1 "$quarantine_path" 2>/dev/null || echo "")
    
    if [[ -z "$quarantined_releases" ]]; then
        info "No quarantined releases found"
        return 0
    fi
    
    # Check each quarantined release
    while IFS= read -r version; do
        if [[ -n "$version" ]]; then
            local release_path="${quarantine_path}/${version}"
            local release_age
            release_age=$(( $(date +%s) - $(stat -c %Y "$release_path") ))
            local release_age_days=$((release_age / 86400))
            
            if [[ $release_age_days -ge $QUARANTINE_DAYS ]]; then
                if ! is_critical_site "$site"; then
                    request_approval "$site" "delete_quarantined"
                    delete_quarantined_release "$site" "$version"
                else
                    info "Skipping critical site release: $version"
                fi
            else
                info "Release $version: $release_age_days days old (quarantine: $QUARANTINE_DAYS days)"
            fi
        fi
    done <<< "$quarantined_releases"
}

cleanup_old_backups() {
    local site="$1"
    local backup_path
    backup_path=$(get_backup_path "$site")
    
    if [[ ! -d "$backup_path" ]]; then
        info "No backup directory"
        return 0
    fi
    
    log "Cleaning up old backups for $site"
    
    # Get all backups
    local backups
    backups=$(list_backups "$site")
    
    if [[ -z "$backups" ]]; then
        info "No backups found"
        return 0
    fi
    
    # Check each backup
    while IFS= read -r backup_file; do
        if [[ -n "$backup_file" ]]; then
            local backup_age
            backup_age=$(( $(date +%s) - $(stat -c %Y "$backup_file") ))
            local backup_age_days=$((backup_age / 86400))
            
            if [[ $backup_age_days -ge $BACKUP_RETENTION_DAYS ]]; then
                delete_old_backup "$backup_file"
            else
                info "Backup $(basename "$backup_file"): $backup_age_days days old (retention: $BACKUP_RETENTION_DAYS days)"
            fi
        fi
    done <<< "$backups"
}

run_gc() {
    local site="$1"
    
    echo ""
    echo "========================================"
    echo "  RELEASE GARBAGE COLLECTION: $site"
    echo "========================================"
    echo ""
    
    # Cleanup old releases
    cleanup_old_releases "$site"
    
    # Cleanup quarantined releases
    cleanup_quarantined_releases "$site"
    
    # Cleanup old backups
    cleanup_old_backups "$site"
    
    echo ""
    echo "========================================"
    echo "  GARBAGE COLLECTION COMPLETE"
    echo "========================================"
    echo ""
    
    success "Garbage collection completed for $site"
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
            --quarantine-days)
                QUARANTINE_DAYS="$2"
                shift 2
                ;;
            --keep-releases)
                KEEP_RELEASES="$2"
                shift 2
                ;;
            --backup-retention)
                BACKUP_RETENTION_DAYS="$2"
                shift 2
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
        exit 1
    fi
    
    # Validate site exists
    if ! validate_site_exists "$SITE_NAME"; then
        exit 1
    fi
    
    # Run garbage collection
    run_gc "$SITE_NAME"
}

main "$@"