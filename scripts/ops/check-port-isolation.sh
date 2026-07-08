#!/usr/bin/env bash
# Validate registry port isolation and optional live listener conflicts (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
# shellcheck source=../deploy/lib/asdev-common.sh
source "${PROJECT_ROOT}/scripts/deploy/lib/asdev-common.sh"
REGISTRY="${PROJECT_ROOT}/deploy/registry.tsv"
CHECK_LIVE=false
SITE_FILTER=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check staging/production port isolation in registry.
Optionally check live listeners (read-only).

Options:
  --live              Also probe local listeners (ss/lsof)
  --site <id>         Only one site
  --registry <path>   Registry path
  -h, --help
EOF
}

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
err() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; ERRORS=$((ERRORS+1)); }
ERRORS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --live) CHECK_LIVE=true; shift ;;
    --site) SITE_FILTER="$2"; shift 2 ;;
    --registry) REGISTRY="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

declare -A USED_PORTS=()

while IFS=$'\t' read -r site_id _rest; do
  [[ "$site_id" == "site_id" || -z "$site_id" ]] && continue
  [[ -n "$SITE_FILTER" && "$site_id" != "$SITE_FILTER" ]] && continue
  prod=$(awk -F'\t' -v s="$site_id" '$1==s{print $12}' "$REGISTRY")
  stg=$(awk -F'\t' -v s="$site_id" '$1==s{print $21}' "$REGISTRY")
  if [[ "$prod" == "$stg" ]]; then
    err "$site_id: prod_port==staging_port ($prod)"
  else
    ok "$site_id: prod=$prod staging=$stg isolated"
  fi
  if [[ -n "${USED_PORTS[$prod]:-}" ]]; then
    err "port $prod used by both ${USED_PORTS[$prod]} and $site_id(prod)"
  else
    USED_PORTS[$prod]="$site_id(prod)"
  fi
  if [[ -n "${USED_PORTS[$stg]:-}" ]]; then
    err "port $stg used by both ${USED_PORTS[$stg]} and $site_id(staging)"
  else
    USED_PORTS[$stg]="$site_id(staging)"
  fi

  if [[ "$CHECK_LIVE" == "true" ]]; then
    if asdev_port_is_listening "$prod"; then
      log "LIVE: port $prod listening (owner may be $site_id prod or other)"
    fi
    if asdev_port_is_listening "$stg"; then
      log "LIVE: port $stg listening (owner may be $site_id staging or other)"
    fi
  fi
done < "$REGISTRY"

echo "========================================"
echo "ERRORS=$ERRORS"
if [[ $ERRORS -gt 0 ]]; then
  exit 1
fi
ok "Port isolation checks passed"
exit 0
