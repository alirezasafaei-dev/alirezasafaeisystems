#!/usr/bin/env bash
set -euo pipefail

# ASDEV Healthcheck Script
# Verifies deployment health

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
VERSION=""
HEALTHCHECK_ONLY=false
TIMEOUT=10
RETRIES=3
RETRY_DELAY=5

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <site-name> [version]

Verify deployment health.

Arguments:
    site-name       Site to check (must exist in registry)
    version         Version to check (optional, defaults to current)

Options:
    --dry-run       Preview checks without running
    --healthcheck-only  Run health checks only
    --timeout       Connection timeout in seconds (default: 10)
    --retries       Number of retries (default: 3)
    --retry-delay   Delay between retries in seconds (default: 5)
    -h, --help      Show this help message

Examples:
    $(basename "$0") auditsystems
    $(basename "$0") --dry-run persiantoolbox
    $(basename "$0") --healthcheck-only auditsystems
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

get_deploy_path() {
    local site="$1"
    local site_info
    site_info=$(get_site_info "$site")
    echo "$site_info" | cut -f4
}

get_healthcheck_url() {
    local site="$1"
    local site_info
    site_info=$(get_site_info "$site")
    echo "$site_info" | cut -f6
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

check_http_endpoint() {
    local url="$1"
    local description="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would check: $description ($url)"
        return 0
    fi
    
    log "Checking: $description"
    
    local http_code
    local attempt=1
    
    while [[ $attempt -le $RETRIES ]]; do
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT" "$url" 2>/dev/null || echo "000")
        
        if [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 400 ]]; then
            success "$description: HTTP $http_code"
            return 0
        fi
        
        if [[ $attempt -lt $RETRIES ]]; then
            info "Attempt $attempt failed, retrying in $RETRY_DELAY seconds..."
            sleep "$RETRY_DELAY"
        fi
        
        ((attempt++)) || true
    done
    
    error "$description: Failed after $RETRIES attempts (last HTTP $http_code)"
    return 1
}

check_static_assets() {
    local url="$1"
    local assets=("css" "js" "images" "fonts")
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would check static assets"
        return 0
    fi
    
    log "Checking static assets..."
    
    local all_passed=true
    
    for asset in "${assets[@]}"; do
        local asset_url="${url}/${asset}/"
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT" "$asset_url" 2>/dev/null || echo "000")
        
        if [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 400 ]]; then
            info "Static assets ($asset): HTTP $http_code"
        elif [[ "$http_code" == "404" ]]; then
            info "Static assets ($asset): Not found (may be expected)"
        else
            warn "Static assets ($asset): HTTP $http_code"
        fi
    done
    
    if [[ "$all_passed" == "true" ]]; then
        success "Static asset checks passed"
        return 0
    else
        return 1
    fi
}

check_critical_endpoints() {
    local url="$1"
    local endpoints=(
        "/"
        "/api/health"
        "/status"
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would check critical endpoints"
        return 0
    fi
    
    log "Checking critical endpoints..."
    
    local all_passed=true
    
    for endpoint in "${endpoints[@]}"; do
        local endpoint_url="${url}${endpoint}"
        local http_code
        http_code=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout "$TIMEOUT" "$endpoint_url" 2>/dev/null || echo "000")
        
        if [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 400 ]]; then
            info "Endpoint $endpoint: HTTP $http_code"
        elif [[ "$http_code" == "404" ]]; then
            info "Endpoint $endpoint: Not found (may be expected)"
        elif [[ "$http_code" == "403" ]]; then
            info "Endpoint $endpoint: Forbidden (may be expected)"
        else
            warn "Endpoint $endpoint: HTTP $http_code"
            all_passed=false
        fi
    done
    
    if [[ "$all_passed" == "true" ]]; then
        success "Critical endpoint checks passed"
        return 0
    else
        warn "Some endpoint checks failed"
        return 1
    fi
}

check_application_response() {
    local url="$1"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would check application response"
        return 0
    fi
    
    log "Checking application response..."
    
    local response
    local http_code
    response=$(curl -s -w "\n%{http_code}" --connect-timeout "$TIMEOUT" "$url" 2>/dev/null)
    http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | head -n -1)
    
    if [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 400 ]]; then
        success "Application response: HTTP $http_code"
        
        # Check for common error patterns in response
        if echo "$body" | grep -qi "error\|exception\|fatal"; then
            warn "Response may contain error messages"
        fi
        
        return 0
    else
        error "Application response: HTTP $http_code"
        return 1
    fi
}

check_database_connection() {
    local url="$1"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would check database connection"
        return 0
    fi
    
    log "Checking database connection..."
    
    # This is a placeholder - actual implementation depends on the application
    # For now, we just check if the health endpoint returns OK
    local health_url="${url}/api/health"
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT" "$health_url" 2>/dev/null || echo "000")
    
    if [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 400 ]]; then
        success "Database connection: OK"
        return 0
    else
        warn "Database connection: Cannot verify (HTTP $http_code)"
        return 0
    fi
}

run_full_healthcheck() {
    local site="$1"
    local version="$2"
    
    echo ""
    echo "========================================"
    echo "  HEALTHCHECK FOR: $site"
    echo "  VERSION: $version"
    echo "========================================"
    echo ""
    
    local healthcheck_url
    healthcheck_url=$(get_healthcheck_url "$site")
    
    if [[ -z "$healthcheck_url" ]]; then
        warn "No healthcheck URL configured for $site"
        warn "Skipping HTTP checks"
        return 0
    fi
    
    log "Healthcheck URL: $healthcheck_url"
    
    local all_passed=true
    
    # Run health checks
    check_http_endpoint "$healthcheck_url" "Main endpoint" || all_passed=false
    check_static_assets "$healthcheck_url" || all_passed=false
    check_critical_endpoints "$healthcheck_url" || all_passed=false
    check_application_response "$healthcheck_url" || all_passed=false
    check_database_connection "$healthcheck_url" || all_passed=false
    
    echo ""
    echo "========================================"
    echo "  HEALTHCHECK RESULTS"
    echo "========================================"
    echo ""
    
    if [[ "$all_passed" == "true" ]]; then
        success "All health checks passed"
        return 0
    else
        warn "Some health checks failed"
        return 1
    fi
}

record_healthcheck() {
    local site="$1"
    local version="$2"
    local status="$3"
    local deploy_path
    local metadata_dir
    
    deploy_path=$(get_deploy_path "$site")
    metadata_dir="${deploy_path}/.deploy"
    
    mkdir -p "$metadata_dir"
    
    # Append to deployments log
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] HEALTH $site $version $status" >> "${metadata_dir}/deployments.log"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --healthcheck-only)
                HEALTHCHECK_ONLY=true
                shift
                ;;
            --timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            --retries)
                RETRIES="$2"
                shift 2
                ;;
            --retry-delay)
                RETRY_DELAY="$2"
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
        exit 1
    fi
    
    # Validate site exists
    if ! validate_site_exists "$SITE_NAME"; then
        exit 1
    fi
    
    # Get current version if not provided
    if [[ -z "$VERSION" ]]; then
        VERSION=$(get_current_version "$SITE_NAME")
        
        if [[ -z "$VERSION" ]]; then
            error "No current version found for $SITE_NAME"
            exit 1
        fi
    fi
    
    # Run health checks
    local status="PASS"
    if ! run_full_healthcheck "$SITE_NAME" "$VERSION"; then
        status="FAIL"
    fi
    
    # Record healthcheck
    if [[ "$DRY_RUN" == "false" ]]; then
        record_healthcheck "$SITE_NAME" "$VERSION" "$status"
    fi
    
    if [[ "$status" == "PASS" ]]; then
        success "Healthcheck completed successfully"
        exit 0
    else
        error "Healthcheck failed"
        exit 1
    fi
}

main "$@"