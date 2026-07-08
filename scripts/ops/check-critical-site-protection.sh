#!/usr/bin/env bash
set -euo pipefail

CRITICAL_SITE="persiantoolbox.ir"
DEPLOY_BASE="/srv/asdev/sites/${CRITICAL_SITE}"
CURRENT_LINK="${DEPLOY_BASE}/current"
SHARED_DIR="${DEPLOY_BASE}/shared"
METADATA_FILE="${DEPLOY_BASE}/metadata.json"
NGINX_CONF="/etc/nginx/sites-available/${CRITICAL_SITE}"
PM2_PROCESS_NAME="${CRITICAL_SITE}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "  ${YELLOW}!${NC} $1"
    ((CHECKS_WARNING++))
}

echo "=== CRITICAL_SITE Protection Check: ${CRITICAL_SITE} ==="
echo ""

# 1. Deploy base directory exists
echo "[1/7] Deploy base directory"
if [[ -d "${DEPLOY_BASE}" ]]; then
    check_pass "Deploy base exists: ${DEPLOY_BASE}"
else
    check_fail "Deploy base missing: ${DEPLOY_BASE}"
fi

# 2. Current symlink exists and is valid
echo "[2/7] Current symlink"
if [[ -L "${CURRENT_LINK}" ]]; then
    TARGET=$(readlink -f "${CURRENT_LINK}" 2>/dev/null || true)
    if [[ -n "${TARGET}" && -d "${TARGET}" ]]; then
        check_pass "Current symlink valid → ${TARGET}"
    else
        check_fail "Current symlink broken → target missing"
    fi
else
    check_fail "Current symlink missing or not a symlink"
fi

# 3. Shared directory exists
echo "[3/7] Shared directory"
if [[ -d "${SHARED_DIR}" ]]; then
    FILE_COUNT=$(find "${SHARED_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)
    check_pass "Shared directory exists (${FILE_COUNT} files)"
else
    check_fail "Shared directory missing: ${SHARED_DIR}"
fi

# 4. Nginx config found
echo "[4/7] Nginx configuration"
if [[ -f "${NGINX_CONF}" ]]; then
    if nginx -t 2>/dev/null; then
        check_pass "Nginx config valid"
    else
        check_warn "Nginx config exists but nginx -t failed"
    fi
else
    check_fail "Nginx config missing: ${NGINX_CONF}"
fi

# 5. PM2 process running
echo "[5/7] PM2 process"
if command -v pm2 &>/dev/null; then
    PM2_STATUS=$(pm2 jlist 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for p in data:
        if p.get('name') == '${PM2_PROCESS_NAME}':
            print(p.get('pm2_env', {}).get('status', 'unknown'))
            sys.exit(0)
    print('not_found')
except:
    print('error')
" 2>/dev/null || echo "not_found")

    case "${PM2_STATUS}" in
        online)
            check_pass "PM2 process is online"
            ;;
        stopped)
            check_warn "PM2 process exists but is stopped"
            ;;
        not_found)
            check_fail "PM2 process not found: ${PM2_PROCESS_NAME}"
            ;;
        *)
            check_warn "PM2 process status uncertain: ${PM2_STATUS}"
            ;;
    esac
else
    check_fail "PM2 not installed"
fi

# 6. Metadata file exists
echo "[6/7] Metadata file"
if [[ -f "${METADATA_FILE}" ]]; then
    DEPLOY_TIME=$(python3 -c "
import json
try:
    with open('${METADATA_FILE}') as f:
        d = json.load(f)
    print(d.get('deployed_at', 'unknown'))
except:
    print('parse_error')
" 2>/dev/null || echo "parse_error")
    check_pass "Metadata exists (deployed_at: ${DEPLOY_TIME})"
else
    check_warn "Metadata file missing (non-critical but recommended)"
fi

# 7. Overall deployment integrity
echo "[7/7] Deployment integrity"
if [[ -L "${CURRENT_LINK}" && -d "${SHARED_DIR}" ]]; then
    if [[ -f "${CURRENT_LINK}/package.json" ]] || [[ -f "${CURRENT_LINK}/app.js" ]] || [[ -f "${CURRENT_LINK}/server.js" ]]; then
        check_pass "Deployment appears valid (application files found)"
    else
        check_warn "Deployment exists but no standard app entry point found"
    fi
else
    check_fail "Cannot verify deployment integrity"
fi

# Summary
echo ""
echo "=== Summary ==="
echo -e "  Passed:   ${GREEN}${CHECKS_PASSED}${NC}"
echo -e "  Warnings: ${YELLOW}${CHECKS_WARNING}${NC}"
echo -e "  Failed:   ${RED}${CHECKS_FAILED}${NC}"
echo ""

if [[ ${CHECKS_FAILED} -eq 0 ]]; then
    echo -e "${GREEN}PROTECTION STATUS: OK${NC}"
    exit 0
elif [[ ${CHECKS_FAILED} -le 2 ]]; then
    echo -e "${YELLOW}PROTECTION STATUS: DEGRADED${NC}"
    exit 1
else
    echo -e "${RED}PROTECTION STATUS: CRITICAL${NC}"
    exit 2
fi
