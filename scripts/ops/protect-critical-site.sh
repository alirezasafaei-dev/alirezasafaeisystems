#!/usr/bin/env bash
set -euo pipefail

CRITICAL_SITE="persiantoolbox.ir"
DEPLOY_BASE="/srv/asdev/sites/${CRITICAL_SITE}"
OVERRIDE_VAR="EMERGENCY_OVERRIDE_CRITICAL_SITE"
OVERRIDE_LOG="/var/log/critical-site-overrides.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  check       Verify protection status (default)"
    echo "  deploy      Deploy to CRITICAL_SITE (requires deploy path)"
    echo "  stop        Stop PM2 process (blocked without override)"
    echo "  restart     Restart PM2 process (blocked without override)"
    echo "  remove      Remove deploy directory (blocked without override)"
    echo "  symlink     Update current symlink (blocked without override)"
    echo "  drop-db     Drop database (blocked without override)"
    echo ""
    echo "Options:"
    echo "  --dry-run           Show what would happen without executing"
    echo "  --deploy-path PATH  Path to deploy (for deploy action)"
    echo "  --target PATH       Target for symlink update"
    echo ""
    echo "Emergency Override:"
    echo "  export ${OVERRIDE_VAR}=<phrase>"
    echo "  $0 <action>"
    echo ""
    echo "Default mode: check (verify protection status)"
    exit 1
}

log_override() {
    local action="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local user=$(whoami)
    mkdir -p "$(dirname "${OVERRIDE_LOG}")"
    echo "[${timestamp}] OVERRIDE by ${user}: action=${action} site=${CRITICAL_SITE}" >> "${OVERRIDE_LOG}"
}

check_override() {
    if [[ -n "${!OVERRIDE_VAR:-}" ]]; then
        if [[ "${!OVERRIDE_VAR}" == "EMERGENCY_OVERRIDE_CRITICAL_SITE" ]]; then
            echo -e "${YELLOW}EMERGENCY OVERRIDE ACTIVE${NC}"
            echo -e "${YELLOW}All destructive actions are permitted.${NC}"
            echo -e "${YELLOW}This will be logged for review.${NC}"
            return 0
        else
            echo -e "${RED}Invalid override phrase${NC}"
            return 1
        fi
    fi
    return 1
}

block_action() {
    local action="$1"
    echo -e "${RED}BLOCKED: ${action} on CRITICAL_SITE (${CRITICAL_SITE})${NC}"
    echo -e "${RED}This action is prohibited by the CRITICAL_SITE protection policy.${NC}"
    echo -e "${YELLOW}To override, set: export ${OVERRIDE_VAR}=EMERGENCY_OVERRIDE_CRITICAL_SITE${NC}"
    exit 2
}

ACTION="check"
DRY_RUN=false
DEPLOY_PATH=""
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        check|deploy|stop|restart|remove|symlink|drop-db)
            ACTION="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --deploy-path)
            DEPLOY_PATH="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

case "${ACTION}" in
    check)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        CHECK_SCRIPT="${SCRIPT_DIR}/check-critical-site-protection.sh"
        if [[ -x "${CHECK_SCRIPT}" ]]; then
            exec "${CHECK_SCRIPT}"
        else
            bash "${CHECK_SCRIPT}"
        fi
        ;;

    deploy)
        echo "=== Deploy to CRITICAL_SITE: ${CRITICAL_SITE} ==="
        if [[ -z "${DEPLOY_PATH}" ]]; then
            echo -e "${RED}Error: --deploy-path required for deploy action${NC}"
            exit 1
        fi
        if [[ ! -d "${DEPLOY_PATH}" ]]; then
            echo -e "${RED}Error: Deploy path does not exist: ${DEPLOY_PATH}${NC}"
            exit 1
        fi
        if ${DRY_RUN}; then
            echo -e "${CYAN}[DRY RUN] Would deploy from: ${DEPLOY_PATH}${NC}"
            echo -e "${CYAN}[DRY RUN] Would update symlink: ${DEPLOY_BASE}/current → ${DEPLOY_PATH}${NC}"
            exit 0
        fi
        echo "Deploy path validated: ${DEPLOY_PATH}"
        echo "Updating symlink..."
        ln -sfn "${DEPLOY_PATH}" "${DEPLOY_BASE}/current"
        echo -e "${GREEN}Symlink updated successfully${NC}"

        if command -v pm2 &>/dev/null; then
            echo "Restarting PM2 process..."
            pm2 reload "${CRITICAL_SITE}" --update-env 2>/dev/null || \
                pm2 restart "${CRITICAL_SITE}" 2>/dev/null || \
                echo -e "${YELLOW}Warning: PM2 restart failed (process may need manual restart)${NC}"
        fi
        echo -e "${GREEN}Deploy complete${NC}"
        ;;

    stop)
        if ${DRY_RUN}; then
            echo -e "${CYAN}[DRY RUN] Would stop PM2 process: ${CRITICAL_SITE}${NC}"
            exit 0
        fi
        if ! check_override; then
            block_action "stop PM2 process"
        fi
        log_override "stop"
        pm2 stop "${CRITICAL_SITE}"
        echo -e "${GREEN}PM2 process stopped${NC}"
        ;;

    restart)
        if ${DRY_RUN}; then
            echo -e "${CYAN}[DRY RUN] Would restart PM2 process: ${CRITICAL_SITE}${NC}"
            exit 0
        fi
        if ! check_override; then
            block_action "restart PM2 process"
        fi
        log_override "restart"
        pm2 restart "${CRITICAL_SITE}"
        echo -e "${GREEN}PM2 process restarted${NC}"
        ;;

    remove)
        if ${DRY_RUN}; then
            echo -e "${CYAN}[DRY RUN] Would remove deploy directory: ${DEPLOY_BASE}${NC}"
            exit 0
        fi
        if ! check_override; then
            block_action "remove deploy directory"
        fi
        log_override "remove"
        echo -e "${YELLOW}Removing deploy directory: ${DEPLOY_BASE}${NC}"
        rm -rf "${DEPLOY_BASE}"
        echo -e "${GREEN}Deploy directory removed${NC}"
        ;;

    symlink)
        if ${DRY_RUN}; then
            echo -e "${CYAN}[DRY RUN] Would update symlink: ${DEPLOY_BASE}/current → ${TARGET}${NC}"
            exit 0
        fi
        if ! check_override; then
            block_action "manually modify symlink"
        fi
        if [[ -z "${TARGET}" ]]; then
            echo -e "${RED}Error: --target required for symlink action${NC}"
            exit 1
        fi
        log_override "symlink"
        ln -sfn "${TARGET}" "${DEPLOY_BASE}/current"
        echo -e "${GREEN}Symlink updated: ${TARGET}${NC}"
        ;;

    drop-db)
        if ${DRY_RUN}; then
            echo -e "${CYAN}[DRY RUN] Would drop database for: ${CRITICAL_SITE}${NC}"
            exit 0
        fi
        if ! check_override; then
            block_action "drop database"
        fi
        log_override "drop-db"
        echo -e "${RED}CRITICAL: Database drop is irreversible${NC}"
        read -p "Type 'DESTROY' to confirm: " CONFIRM
        if [[ "${CONFIRM}" == "DESTROY" ]]; then
            echo -e "${YELLOW}Database drop confirmed by operator${NC}"
            echo -e "${YELLOW}Manual database drop required — no automation provided for safety${NC}"
        else
            echo "Aborted."
            exit 1
        fi
        ;;

    *)
        usage
        ;;
esac
