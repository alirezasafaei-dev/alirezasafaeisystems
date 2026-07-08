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
# scripts/ops -> repo root (not scripts/)
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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

# Ignore detection-only lines (regex allowlists / pattern arrays), not live commands.
is_detection_only_line() {
    local line="$1"
    # Quoted regex fragments used by protection checkers themselves.
    if echo "$line" | grep -qE "dangerous_patterns|\\\\s\\+|\\[\\]|grep -[a-zA-Z]*E|'[a-z]+\\\\s"; then
        return 0
    fi
    # Message / log strings describing forbidden ops.
    if echo "$line" | grep -qiE 'echo|log_|printf|warn|error|USAGE|pattern'; then
        return 0
    fi
    return 1
}

filter_actionable_matches() {
    # stdin: grep -n output; stdout: actionable lines only
    local line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if is_detection_only_line "$line"; then
            continue
        fi
        printf '%s\n' "$line"
    done
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-root) PROJECT_ROOT="$(cd "$2" && pwd)"; shift 2 ;;
        -h|--help)      usage; exit 0 ;;
        *)              echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

log "Checking for dangerous patterns in $PROJECT_ROOT"

if [[ -d "$PROJECT_ROOT/scripts/deploy" ]]; then
    log "--- Checking deploy scripts for eval ---"
    while IFS= read -r file; do
        # Only flag real eval invocations, not comments/docs.
        matches=$(grep -nE '(^|[^[:alnum:]_])eval[[:space:]]' "$file" 2>/dev/null | grep -vE '^\s*#|echo|printf|USAGE|documentation' || true)
        if [[ -n "$matches" ]]; then
            printf '%s\n' "$matches"
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
                matches=$(grep -n 'rm -rf' "$file" 2>/dev/null | filter_actionable_matches || true)
                if [[ -n "$matches" ]]; then
                    printf '%s\n' "$matches"
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
                matches=$(grep -nE 'pm2[[:space:]]+(stop|restart|delete)' "$file" 2>/dev/null | filter_actionable_matches || true)
                if [[ -n "$matches" ]]; then
                    printf '%s\n' "$matches"
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
                # Flag live invocations only (not regex allowlist strings).
                matches=$(grep -nE '(^|[^[:alnum:]_])(sudo[[:space:]]+)?nginx([[:space:]]+-s[[:space:]]+reload|[[:space:]]+reload|[[:space:]]+restart)' "$file" 2>/dev/null | filter_actionable_matches || true)
                if [[ -n "$matches" ]]; then
                    printf '%s\n' "$matches"
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
                matches=$(grep -nE 'ln[[:space:]]+(-sfn|-snf|-sf)' "$file" 2>/dev/null | filter_actionable_matches || true)
                if [[ -n "$matches" ]]; then
                    printf '%s\n' "$matches"
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
