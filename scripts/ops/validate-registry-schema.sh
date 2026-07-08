#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
REGISTRY="$PROJECT_ROOT/deploy/registry.tsv"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log()   { echo -e "${BLUE}[$(date -u +%Y-%m-%dT%H:%M:%SZ)]${NC} $1"; }
warn()  { echo -e "${YELLOW}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN:${NC} $1"; ((WARNINGS++)) || true; }
error() { echo -e "${RED}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR:${NC} $1"; ((ERRORS++)) || true; }
ok()    { echo -e "${GREEN}[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK:${NC} $1"; }

# 21 columns: added staging_port for env isolation
EXPECTED_COLS=21

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Validate registry.tsv schema consistency.

Checks:
  - Each row has exactly $EXPECTED_COLS columns
  - protected is true/false
  - prod_port (col 12) numeric when mode=local-port
  - staging_port (col 21) numeric when mode=local-port
  - prod_port != staging_port (port isolation)
  - healthcheck_path starts with / or is "-"

Options:
  --registry <path>   Path to registry.tsv (default: deploy/registry.tsv)
  -h, --help          Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --registry) REGISTRY="$2"; shift 2 ;;
        -h|--help)  usage; exit 0 ;;
        *)          echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

if [[ ! -f "$REGISTRY" ]]; then
    echo -e "${RED}Registry file not found: $REGISTRY${NC}" >&2
    exit 1
fi

log "Validating registry: $REGISTRY"

line_num=0
while IFS= read -r line; do
    ((line_num++)) || true

    if [[ $line_num -eq 1 ]]; then
        header_cols=$(echo "$line" | awk -F'\t' '{print NF}')
        if [[ "$header_cols" -ne "$EXPECTED_COLS" ]]; then
            error "Header has $header_cols columns, expected $EXPECTED_COLS"
        else
            ok "Header has $EXPECTED_COLS columns"
        fi
        # Accept prod_port or legacy healthcheck_port in header col 12 name
        col12=$(echo "$line" | cut -f12)
        if [[ "$col12" != "prod_port" && "$col12" != "healthcheck_port" ]]; then
            warn "Header col12 is '$col12' (expected prod_port or healthcheck_port)"
        fi
        col21=$(echo "$line" | cut -f21)
        if [[ "$col21" != "staging_port" ]]; then
            error "Header col21 is '$col21' (expected staging_port)"
        fi
        continue
    fi

    site_id=$(echo "$line" | cut -f1)
    if [[ -z "$site_id" ]]; then
        warn "Line $line_num: empty site_id"
        continue
    fi

    row_cols=$(echo "$line" | awk -F'\t' '{print NF}')
    if [[ "$row_cols" -ne "$EXPECTED_COLS" ]]; then
        error "Line $line_num ($site_id): has $row_cols columns, expected $EXPECTED_COLS"
        continue
    fi

    protected=$(echo "$line" | cut -f4)
    if [[ "$protected" != "true" && "$protected" != "false" ]]; then
        error "Line $line_num ($site_id): protected='$protected' (must be true or false)"
    fi

    hc_mode=$(echo "$line" | cut -f10)
    prod_port=$(echo "$line" | cut -f12)
    staging_port=$(echo "$line" | cut -f21)

    if [[ "$hc_mode" == "local-port" ]]; then
        if [[ "$prod_port" == "-" || -z "$prod_port" ]]; then
            error "Line $line_num ($site_id): local-port requires prod_port"
        elif ! [[ "$prod_port" =~ ^[0-9]+$ ]]; then
            error "Line $line_num ($site_id): prod_port='$prod_port' is not numeric"
        fi
        if [[ "$staging_port" == "-" || -z "$staging_port" ]]; then
            error "Line $line_num ($site_id): local-port requires staging_port"
        elif ! [[ "$staging_port" =~ ^[0-9]+$ ]]; then
            error "Line $line_num ($site_id): staging_port='$staging_port' is not numeric"
        fi
        if [[ "$prod_port" == "$staging_port" ]]; then
            error "Line $line_num ($site_id): prod_port and staging_port must differ (both $prod_port)"
        fi
    fi

    hc_path=$(echo "$line" | cut -f13)
    if [[ -n "$hc_path" && "$hc_path" != "-" ]]; then
        if [[ "$hc_path" != /* ]]; then
            error "Line $line_num ($site_id): healthcheck_path='$hc_path' does not start with /"
        fi
    fi

    ok "Line $line_num ($site_id): valid (prod_port=$prod_port staging_port=$staging_port)"
done < "$REGISTRY"

echo ""
echo "========================================"
echo "  REGISTRY VALIDATION RESULTS"
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo "========================================"
echo ""

if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}Validation FAILED${NC}"
    exit 1
fi

echo -e "${GREEN}All checks passed${NC}"
exit 0
