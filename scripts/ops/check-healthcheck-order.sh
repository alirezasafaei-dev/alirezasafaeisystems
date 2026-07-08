#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Check Healthcheck Order in Deploy Script
# =============================================================================
# Validates that the deploy script follows the correct healthcheck model:
#   1. Build and prepare release
#   2. Switch symlink (post-activation)
#   3. Run healthcheck AFTER symlink switch
#   4. Roll back if post-activation healthcheck fails
#
# Exit code 0 = validation passed
# Exit code 1 = validation failed
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"; }
pass()  { echo -e "${GREEN}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] PASS:${NC} $1"; }
fail()  { echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] FAIL:${NC} $1" >&2; }
warn()  { echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN:${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DEPLOY_SCRIPT="${PROJECT_ROOT}/scripts/deploy/asdev-deploy.sh"

FAILURES=0

check_file_exists() {
    if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
        fail "Deploy script not found: $DEPLOY_SCRIPT"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
    return 0
}

check_symlink_before_healthcheck() {
    local script_content="$1"
    local symlink_line healthcheck_line

    symlink_line=$(grep -n 'ln -sfn.*current_link\|ln.*current.*release' "$DEPLOY_SCRIPT" | head -1 | cut -d: -f1 || true)
    healthcheck_line=$(grep -n 'curl.*healthcheck\|curl.*hc_url\|hc_ok\|Running healthcheck' "$DEPLOY_SCRIPT" | head -1 | cut -d: -f1 || true)

    if [[ -z "$symlink_line" ]]; then
        fail "Symlink switch (ln -sfn) not found in deploy script"
        FAILURES=$((FAILURES + 1))
        return
    fi

    if [[ -z "$healthcheck_line" ]]; then
        fail "Healthcheck (curl) not found in deploy script"
        FAILURES=$((FAILURES + 1))
        return
    fi

    if [[ "$symlink_line" -lt "$healthcheck_line" ]]; then
        pass "Symlink switch (line $symlink_line) occurs BEFORE healthcheck (line $healthcheck_line) — post-activation model correct"
    else
        fail "Healthcheck (line $healthcheck_line) occurs BEFORE symlink switch (line $symlink_line) — should be post-activation"
        FAILURES=$((FAILURES + 1))
    fi
}

check_rollback_on_healthcheck_failure() {
    local script_content="$1"

    if grep -q 'Healthcheck failed.*current NOT modified\|hc_ok.*false.*error\|Post-activation healthcheck failed\|hc_ok.*false.*error\|rolling back symlink' "$DEPLOY_SCRIPT"; then
        pass "Healthcheck failure handling found (blocks or rolls back on failure)"
    else
        fail "No explicit healthcheck failure handling found — deploy should fail gracefully on healthcheck failure"
        FAILURES=$((FAILURES + 1))
    fi

    if grep -q 'ln -sfn.*previous\|ln.*rollback\|ln.*previous.*release\|ln -sfn.*last_known_good\|Rolled back symlink\|rolling back symlink' "$DEPLOY_SCRIPT" 2>/dev/null; then
        pass "Rollback symlink switch found — rollback mechanism present"
    else
        warn "No automatic rollback symlink switch found — manual rollback required"
    fi
}

check_no_pre_activation_healthcheck() {
    local script_content="$1"
    local first_hc_line first_symlink_line

    first_hc_line=$(grep -n 'curl.*healthcheck\|curl.*hc_url\|hc_ok\|Running healthcheck' "$DEPLOY_SCRIPT" | head -1 | cut -d: -f1 || true)
    first_symlink_line=$(grep -n 'ln -sfn.*current_link\|ln.*current.*release' "$DEPLOY_SCRIPT" | head -1 | cut -d: -f1 || true)

    if [[ -n "$first_hc_line" ]] && [[ -n "$first_symlink_line" ]]; then
        if [[ "$first_hc_line" -lt "$first_symlink_line" ]]; then
            fail "Pre-activation healthcheck detected (line $first_hc_line) before symlink (line $first_symlink_line) — healthcheck should be post-activation only"
            FAILURES=$((FAILURES + 1))
        else
            pass "No pre-activation healthcheck — healthcheck is post-activation"
        fi
    fi
}

main() {
    log "Validating healthcheck model in deploy script"
    log "Deploy script: $DEPLOY_SCRIPT"
    echo ""

    if ! check_file_exists; then
        exit 1
    fi

    local script_content
    script_content=$(cat "$DEPLOY_SCRIPT")

    log "=== Check 1: Symlink switch before healthcheck (post-activation) ==="
    check_symlink_before_healthcheck "$script_content"
    echo ""

    log "=== Check 2: No pre-activation healthcheck ==="
    check_no_pre_activation_healthcheck "$script_content"
    echo ""

    log "=== Check 3: Rollback on healthcheck failure ==="
    check_rollback_on_healthcheck_failure "$script_content"
    echo ""

    if [[ "$FAILURES" -eq 0 ]]; then
        pass "All healthcheck model validations passed"
        exit 0
    else
        fail "$FAILURES validation(s) failed"
        exit 1
    fi
}

main "$@"
