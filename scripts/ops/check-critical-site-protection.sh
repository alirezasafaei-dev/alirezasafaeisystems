#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# CRITICAL SITE PROTECTION CHECK
# =============================================================================
# This script performs READ-ONLY validation checks to ensure no destructive
# operations target the critical site. It never executes any write or mutating
# commands. It is a pure guard/check script.
#
# Exit code 0 = all checks passed (safe)
# Exit code 1 = unsafe condition detected
# =============================================================================

# --- Configuration -----------------------------------------------------------

CRITICAL_SITE="${CRITICAL_SITE:-persiantoolbox.ir}"
CRITICAL_SITE_PATH="${CRITICAL_SITE_PATH:-/srv/asdev/sites/persiantoolbox.ir}"
DEPLOY_BASE="${DEPLOY_BASE:-/srv/asdev/sites}"

# Redacted reason for unsafe conditions (never expose internal paths)
REDACTED_UNSAFE_REASON="Operation targets CRITICAL_SITE or its controlled paths"

# --- Helpers -----------------------------------------------------------------

log_info() {
    echo "[check][INFO]  $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1"
}

log_error() {
    echo "[check][ERROR] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >&2
}

log_safe() {
    echo "[check][SAFE]  $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1"
}

# --- Checks ------------------------------------------------------------------
# Each check is read-only. Failures set SAFE=false and print a redacted reason.

SAFE=true

# 1. Path validation — ensure no dangerous target paths are requested
check_path_safety() {
    local target="${1:-}"
    if [[ -z "$target" ]]; then
        return 0
    fi

    # Resolve without creating or following symlinks
    local resolved
    resolved="$(realpath -m "$target" 2>/dev/null || echo "$target")"

    # Block access to critical site directory
    if [[ "$resolved" == "$CRITICAL_SITE_PATH"* ]]; then
        log_error "$REDACTED_UNSAFE_REASON"
        SAFE=false
    fi

    # Block access to deploy base if it resolves to critical site
    if [[ "$resolved" == "$DEPLOY_BASE"* ]]; then
        local subpath="${resolved#"$DEPLOY_BASE"/}"
        if [[ "$subpath" == "$CRITICAL_SITE"* ]] || [[ "$subpath" == "$CRITICAL_SITE" ]]; then
            log_error "$REDACTED_UNSAFE_REASON"
            SAFE=false
        fi
    fi
}

# 2. Command validation — ensure no destructive commands are present in input
check_command_safety() {
    local cmd_input="${1:-}"
    if [[ -z "$cmd_input" ]]; then
        return 0
    fi

    local dangerous_patterns=(
        'rm\s+(-[rfv]+\s+)*.*('"$CRITICAL_SITE"'|'"$CRITICAL_SITE_PATH"')'
        'rm\s+.*'"$DEPLOY_BASE"'/.*'"$CRITICAL_SITE"
        'pm2\s+(restart|stop|delete)\s+.*'"$CRITICAL_SITE"
        'nginx\s+(reload|restart)'
        'ln\s+-s.*'"$CRITICAL_SITE_PATH"
        'ln\s+-s.*'"$DEPLOY_BASE"'/.*'"$CRITICAL_SITE"
        'DROP\s+(TABLE|DATABASE).*'"$CRITICAL_SITE"
        'mysqldump.*'"$CRITICAL_SITE"
        'pg_dump.*'"$CRITICAL_SITE"
        'rsync.*--delete.*'"$CRITICAL_SITE"
        'deploy\s+.*'"$CRITICAL_SITE"
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if echo "$cmd_input" | grep -qiE "$pattern"; then
            log_error "$REDACTED_UNSAFE_REASON"
            SAFE=false
            return
        fi
    done
}

# 3. Symlink validation — detect if critical site path is used as symlink target
check_symlink_safety() {
    local link_path="${1:-}"
    if [[ -z "$link_path" ]]; then
        return 0
    fi

    if [[ -L "$link_path" ]]; then
        local link_target
        link_target="$(readlink "$link_path" 2>/dev/null || echo "")"
        if [[ "$link_target" == *"$CRITICAL_SITE"* ]] || [[ "$link_target" == "$CRITICAL_SITE_PATH"* ]]; then
            log_error "$REDACTED_UNSAFE_REASON"
            SAFE=false
        fi
    fi
}

# 4. Policy validation — check that CRITICAL_SITE env is set and not overridden
check_policy() {
    if [[ -z "${CRITICAL_SITE:-}" ]]; then
        log_error "$REDACTED_UNSAFE_REASON"
        SAFE=false
    fi
}

# --- Main --------------------------------------------------------------------

main() {
    log_info "Starting critical site protection checks"
    log_info "Critical site: ${CRITICAL_SITE}"

    check_policy

    # Validate command-line arguments if provided
    if [[ $# -gt 0 ]]; then
        local target="${1:-}"
        check_path_safety "$target"
        check_command_safety "$target"
        check_symlink_safety "$target"
    fi

    if [[ "$SAFE" == "true" ]]; then
        log_safe "All protection checks passed"
        exit 0
    else
        log_error "Protection check FAILED — unsafe condition detected"
        exit 1
    fi
}

main "$@"
