#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# CRITICAL SITE PROTECTION GUARD
# =============================================================================
# This script acts as a guard that validates proposed operations before they
# execute against the critical site. It never runs destructive commands.
# It provides dry-run simulation and policy validation.
#
# Exit code 0 = guard passed (operation is safe)
# Exit code 1 = guard blocked (operation is unsafe)
# =============================================================================

# --- Configuration -----------------------------------------------------------

CRITICAL_SITE="${CRITICAL_SITE:-persiantoolbox.ir}"
CRITICAL_SITE_PATH="${CRITICAL_SITE_PATH:-/srv/asdev/sites/persiantoolbox.ir}"
DEPLOY_BASE="${DEPLOY_BASE:-/srv/asdev/sites}"

REDACTED_UNSAFE_REASON="Operation targets CRITICAL_SITE or its controlled paths"

# --- Helpers -----------------------------------------------------------------

log_info() {
    echo "[guard][INFO]  $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1"
}

log_error() {
    echo "[guard][ERROR] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >&2
}

log_safe() {
    echo "[guard][SAFE]  $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1"
}

# --- Guard Checks (read-only) -----------------------------------------------

GUARD_SAFE=true

# 1. Detect dangerous target paths
guard_path() {
    local target="${1:-}"
    [[ -z "$target" ]] && return 0

    local resolved
    resolved="$(realpath -m "$target" 2>/dev/null || echo "$target")"

    if [[ "$resolved" == "$CRITICAL_SITE_PATH"* ]]; then
        log_error "$REDACTED_UNSAFE_REASON"
        GUARD_SAFE=false
    fi

    if [[ "$resolved" == "$DEPLOY_BASE"* ]]; then
        local subpath="${resolved#"$DEPLOY_BASE"/}"
        if [[ "$subpath" == "$CRITICAL_SITE"* ]]; then
            log_error "$REDACTED_UNSAFE_REASON"
            GUARD_SAFE=false
        fi
    fi
}

# 2. Detect commands that would affect CRITICAL_SITE
guard_command() {
    local cmd_input="${1:-}"
    [[ -z "$cmd_input" ]] && return 0

    local patterns=(
        'rm\s+.*('"$CRITICAL_SITE"'|'"$CRITICAL_SITE_PATH"')'
        'pm2\s+(restart|stop|delete)\s+.*'"$CRITICAL_SITE"
        'nginx\s+(reload|restart)'
        'ln\s+-s.*'"$CRITICAL_SITE_PATH"
        'ln\s+-s.*'"$DEPLOY_BASE"'/.*'"$CRITICAL_SITE"
        'DROP\s+(TABLE|DATABASE)'
        'deploy\s+.*'"$CRITICAL_SITE"
        'rsync.*--delete.*'"$CRITICAL_SITE"
        'mv\s+.*'"$CRITICAL_SITE_PATH"
        'mv\s+.*'"$DEPLOY_BASE"'/.*'"$CRITICAL_SITE"
    )

    for pattern in "${patterns[@]}"; do
        if echo "$cmd_input" | grep -qiE "$pattern"; then
            log_error "$REDACTED_UNSAFE_REASON"
            GUARD_SAFE=false
            return
        fi
    done
}

# 3. Policy validation — ensure CRITICAL_SITE is defined
guard_policy() {
    if [[ -z "${CRITICAL_SITE:-}" ]]; then
        log_error "$REDACTED_UNSAFE_REASON"
        GUARD_SAFE=false
    fi
}

# --- Dry-Run Simulation (no side effects) ------------------------------------

dry_run_guard() {
    local operation="${1:-unknown}"
    local target="${2:-}"

    log_info "[DRY-RUN] Would validate: $operation"
    [[ -n "$target" ]] && log_info "[DRY-RUN] Target path: $target"

    guard_path "$target"
    guard_command "$target"
    guard_policy

    if [[ "$GUARD_SAFE" == "true" ]]; then
        log_safe "[DRY-RUN] Guard passed for: $operation"
    else
        log_error "[DRY-RUN] Guard would BLOCK: $operation"
    fi
}

# --- Main --------------------------------------------------------------------

main() {
    log_info "Starting critical site protection guard"
    log_info "Critical site: ${CRITICAL_SITE}"

    # Validate inputs
    guard_policy

    local target="${1:-}"
    if [[ -n "$target" ]]; then
        guard_path "$target"
        guard_command "$target"
    fi

    if [[ "$GUARD_SAFE" == "true" ]]; then
        log_safe "Guard check passed — operation is safe"
        exit 0
    else
        log_error "Guard check FAILED — unsafe operation blocked"
        exit 1
    fi
}

# Allow dry-run mode via --dry-run flag
if [[ "${1:-}" == "--dry-run" ]]; then
    shift
    dry_run_guard "${1:-unknown}" "${2:-}"
    exit $?
fi

main "$@"
