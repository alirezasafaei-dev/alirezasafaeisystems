#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PATTERNS_FOUND=0

log()   { echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"; }
warn()  { echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR:${NC} $1"; ((PATTERNS_FOUND++)) || true; }
ok()    { echo -e "${GREEN}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK:${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check for dangerous patterns in shell scripts.

Dangerous patterns:
  - eval in deploy scripts
  - rm -rf in protection scripts
  - pm2 stop/restart/delete in protection scripts
  - nginx reload in protection scripts
  - direct symlink switch outside deploy engine

Options:
  --project-root <path>   Project root (default: auto-detect)
  -h, --help              Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-root) PROJECT_ROOT="$2"; shift 2 ;;
        -h|--help)      usage; exit 0 ;;
        *)              echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

log "Checking for dangerous patterns in $PROJECT_ROOT"

if [[ -d "$PROJECT_ROOT/scripts/deploy" ]]; then
    log "--- Checking deploy scripts for eval ---"
    while IFS= read -r file; do
        if grep -n 'eval ' "$file" 2>/dev/null | grep -v '^\s*#' | grep -v 'echo.*eval' | grep -v '"eval' | grep -v "'eval"; then
            error "eval found in deploy script: $file"
        fi
    done < <(find "$PROJECT_ROOT/scripts/deploy" -name '*.sh' -type f)
    ok "Deploy script eval check complete"
fi

if [[ -d "$PROJECT_ROOT/scripts/ops" ]]; then
    log "--- Checking protection scripts for rm -rf ---"
    while IFS= read -r file; do
        local_name=$(basename "$file")
        case "$local_name" in
            protect-*|check-critical-site-protection*|generate-quarantine-plan*)
                if grep -n 'rm -rf' "$file" 2>/dev/null | grep -v '^\s*#' | grep -v 'echo.*rm -rf'; then
                    error "rm -rf found in protection script: $file"
                fi
                ;;
        esac
    done < <(find "$PROJECT_ROOT/scripts/ops" -name '*.sh' -type f)

    log "--- Checking protection scripts for pm2 stop/restart/delete ---"
    while IFS= read -r file; do
        local_name=$(basename "$file")
        case "$local_name" in
            protect-*|check-critical-site-protection*)
                if grep -nE 'pm2\s+(stop|restart|delete)' "$file" 2>/dev/null | grep -v '^\s*#'; then
                    error "pm2 stop/restart/delete found in protection script: $file"
                fi
                ;;
        esac
    done < <(find "$PROJECT_ROOT/scripts/ops" -name '*.sh' -type f)

    log "--- Checking protection scripts for nginx reload ---"
    while IFS= read -r file; do
        local_name=$(basename "$file")
        case "$local_name" in
            protect-*|check-critical-site-protection*)
                if grep -n 'nginx.*reload\|nginx.*-s\s+reload' "$file" 2>/dev/null | grep -v '^\s*#'; then
                    error "nginx reload found in protection script: $file"
                fi
                ;;
        esac
    done < <(find "$PROJECT_ROOT/scripts/ops" -name '*.sh' -type f)

    log "--- Checking for direct symlink switch outside deploy engine ---"
    while IFS= read -r file; do
        local_name=$(basename "$file")
        case "$local_name" in
            protect-*|check-critical-site-protection*|generate-quarantine-plan*)
                if grep -n 'ln -sfn\|ln -snf' "$file" 2>/dev/null | grep -v '^\s*#'; then
                    error "Direct symlink switch found in non-deploy script: $file"
                fi
                ;;
        esac
    done < <(find "$PROJECT_ROOT/scripts/ops" -name '*.sh' -type f)

    ok "Protection script pattern checks complete"
fi

echo ""
echo "========================================"
echo "  DANGEROUS PATTERN CHECK RESULTS"
echo "  Patterns found: $PATTERNS_FOUND"
echo "========================================"
echo ""

if [[ $PATTERNS_FOUND -gt 0 ]]; then
    echo -e "${RED}Dangerous patterns detected — review required${NC}"
    exit 1
fi

echo -e "${GREEN}No dangerous patterns found${NC}"
exit 0
