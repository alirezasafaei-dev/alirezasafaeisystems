#!/usr/bin/env bash
set -euo pipefail

# ASDEV Preflight Script
# Runs pre-deployment checks

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
VERBOSE=false
ERRORS=0
WARNINGS=0

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <site-name>

Run pre-deployment checks for a site.

Arguments:
    site-name       Site to check (must exist in registry)

Options:
    --dry-run       Preview checks without running
    --verbose       Show detailed output
    -h, --help      Show this help message

Examples:
    $(basename "$0") auditsystems
    $(basename "$0") --verbose persiantoolbox
EOF
}

log() {
    echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARNING:${NC} $1"
    ((WARNINGS++)) || true
}

error() {
    echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR:${NC} $1"
    ((ERRORS++)) || true
}

success() {
    echo -e "${GREEN}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SUCCESS:${NC} $1"
}

info() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] INFO:${NC} $1"
    fi
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

get_healthcheck_url() {
    local site="$1"
    local site_info
    site_info=$(get_site_info "$site")
    echo "$site_info" | cut -f6
}

check_registry() {
    local site="$1"
    
    log "Checking registry..."
    
    if [[ ! -f "$REGISTRY" ]]; then
        error "Registry file not found: $REGISTRY"
        return 1
    fi
    
    if ! grep -q "^${site}" "$REGISTRY"; then
        error "Site '$site' not found in registry"
        return 1
    fi
    
    success "Registry check passed"
    return 0
}

check_deploy_path() {
    local site="$1"
    local deploy_path
    deploy_path=$(get_deploy_path "$site")
    
    log "Checking deploy path: $deploy_path"
    
    # Check if path exists
    if [[ -d "$deploy_path" ]]; then
        info "Deploy path exists"
        
        # Check permissions
        if [[ -w "$deploy_path" ]]; then
            info "Deploy path is writable"
        else
            error "Deploy path is not writable"
            return 1
        fi
        
        # Check current symlink
        local current_path="${deploy_path}/current"
        if [[ -L "$current_path" ]]; then
            info "Current symlink exists"
            
            if [[ -d "$current_path" ]]; then
                info "Current symlink points to valid directory"
            else
                warn "Current symlink points to invalid directory"
            fi
        else
            info "No current symlink (first deployment?)"
        fi
    else
        info "Deploy path does not exist (will be created)"
    fi
    
    success "Deploy path check passed"
    return 0
}

check_backup_path() {
    local site="$1"
    local backup_path
    backup_path=$(get_backup_path "$site")
    
    log "Checking backup path: $backup_path"
    
    # Check if path exists
    if [[ -d "$backup_path" ]]; then
        info "Backup path exists"
        
        # Check permissions
        if [[ -w "$backup_path" ]]; then
            info "Backup path is writable"
        else
            error "Backup path is not writable"
            return 1
        fi
        
        # Check available space
        local available_space
        available_space=$(df -k "$backup_path" | tail -1 | awk '{print $4}')
        local used_space
        used_space=$(du -sk "$backup_path" 2>/dev/null | cut -f1)
        
        info "Available space: $((available_space / 1024)) MB"
        info "Used space: $((used_space / 1024)) MB"
        
        # Warn if less than 1GB available
        if [[ $available_space -lt 1048576 ]]; then
            warn "Less than 1GB available space"
        fi
    else
        info "Backup path does not exist (will be created)"
    fi
    
    success "Backup path check passed"
    return 0
}

check_healthcheck_url() {
    local site="$1"
    local healthcheck_url
    healthcheck_url=$(get_healthcheck_url "$site")
    
    log "Checking healthcheck URL: $healthcheck_url"
    
    if [[ -z "$healthcheck_url" ]]; then
        warn "No healthcheck URL configured"
        return 0
    fi
    
    # Check if URL is reachable (optional)
    if command -v curl &> /dev/null; then
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$healthcheck_url" 2>/dev/null || echo "000")
        
        if [[ "$http_code" == "000" ]]; then
            info "Healthcheck URL not reachable (expected if not deployed)"
        elif [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 400 ]]; then
            info "Healthcheck URL is reachable"
        else
            warn "Healthcheck URL returned HTTP $http_code"
        fi
    else
        info "curl not available, skipping URL check"
    fi
    
    success "Healthcheck URL check passed"
    return 0
}

check_conflicting_deployments() {
    local site="$1"
    local deploy_path
    deploy_path=$(get_deploy_path "$site")
    
    log "Checking for conflicting deployments..."
    
    # Check for lock file
    local lock_file="${deploy_path}/.deploy.lock"
    if [[ -f "$lock_file" ]]; then
        local lock_age
        lock_age=$(( $(date +%s) - $(stat -c %Y "$lock_file") ))
        
        # If lock is older than 1 hour, it's stale
        if [[ $lock_age -gt 3600 ]]; then
            warn "Stale lock file found (age: $lock_age seconds)"
            if [[ "$DRY_RUN" == "false" ]]; then
                rm -f "$lock_file"
                info "Removed stale lock file"
            fi
        else
            error "Active deployment lock found (age: $lock_age seconds)"
            return 1
        fi
    fi
    
    # Check for running deployments
    local pid_file="${deploy_path}/.deploy.pid"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        
        if kill -0 "$pid" 2>/dev/null; then
            error "Deployment process still running (PID: $pid)"
            return 1
        else
            warn "Stale PID file found"
            if [[ "$DRY_RUN" == "false" ]]; then
                rm -f "$pid_file"
                info "Removed stale PID file"
            fi
        fi
    fi
    
    success "No conflicting deployments found"
    return 0
}

check_environment() {
    local site="$1"
    
    log "Checking environment..."
    
    # Check required tools
    local tools=("git" "tar" "rsync" "jq")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            info "$tool is available"
        else
            warn "$tool is not available"
        fi
    done
    
    # Check Git repository
    if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
        info "Git repository detected"
        
        # Check for uncommitted changes
        if [[ -n "$(git -C "$PROJECT_ROOT" status --porcelain)" ]]; then
            warn "Uncommitted changes detected"
        else
            info "Working directory is clean"
        fi
        
        # Check current branch
        local branch
        branch=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        info "Current branch: $branch"
    else
        warn "Not a Git repository"
    fi
    
    success "Environment check passed"
    return 0
}

check_disk_space() {
    local site="$1"
    local deploy_path
    deploy_path=$(get_deploy_path "$site")
    
    log "Checking disk space..."
    
    # Get available space
    local available_space
    available_space=$(df -k "$deploy_path" 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
    
    if [[ $available_space -lt 1048576 ]]; then
        warn "Less than 1GB available space"
    elif [[ $available_space -lt 524288 ]]; then
        error "Less than 512MB available space"
        return 1
    else
        info "Available space: $((available_space / 1024)) MB"
    fi
    
    success "Disk space check passed"
    return 0
}

run_all_checks() {
    local site="$1"
    
    echo ""
    echo "========================================"
    echo "  PREFLIGHT CHECKS FOR: $site"
    echo "========================================"
    echo ""
    
    # Reset counters
    ERRORS=0
    WARNINGS=0
    
    # Run checks
    check_registry "$site" || true
    check_deploy_path "$site" || true
    check_backup_path "$site" || true
    check_healthcheck_url "$site" || true
    check_conflicting_deployments "$site" || true
    check_environment "$site" || true
    check_disk_space "$site" || true
    
    echo ""
    echo "========================================"
    echo "  PREFLIGHT RESULTS"
    echo "========================================"
    echo ""
    
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    
    if [[ $ERRORS -gt 0 ]]; then
        error "Preflight checks failed with $ERRORS error(s)"
        return 1
    fi
    
    if [[ $WARNINGS -gt 0 ]]; then
        warn "Preflight checks passed with $WARNINGS warning(s)"
    else
        success "All preflight checks passed"
    fi
    
    return 0
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
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
    
    # Run all checks
    run_all_checks "$SITE_NAME"
}

main "$@"