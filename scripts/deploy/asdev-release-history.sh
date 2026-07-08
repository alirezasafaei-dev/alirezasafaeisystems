#!/usr/bin/env bash
# List release history for a site root (read-only).
set -euo pipefail
SITE_ROOT="${ASDEV_SITE_ROOT:-/srv/asdev/sites/persiantoolbox}"
LIMIT="${LIMIT:-20}"
usage() {
  cat <<EOF
Usage: $(basename "$0") [--site-root PATH] [--limit N]
Print release dirs newest-first with release.meta summary.
EOF
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --site-root) SITE_ROOT="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown $1" >&2; exit 1 ;;
  esac
done
echo "site_root=$SITE_ROOT"
if [[ ! -d "$SITE_ROOT/releases" ]]; then
  echo "NO_RELEASES_DIR"
  exit 0
fi
cur=""
[[ -e "$SITE_ROOT/current" ]] && cur=$(readlink -f "$SITE_ROOT/current" 2>/dev/null || true)
echo "current=${cur:-none}"
echo "----"
count=0
# shellcheck disable=SC2012
for d in $(ls -1dt "$SITE_ROOT/releases"/* 2>/dev/null); do
  [[ -d "$d" ]] || continue
  base=$(basename "$d")
  mark=""
  [[ "$d" == "$cur" ]] && mark="*CURRENT*"
  meta="$d/release.meta"
  if [[ -f "$meta" ]]; then
    commit=$(grep -E '^commit=' "$meta" | head -1 | cut -d= -f2-)
    env=$(grep -E '^environment=' "$meta" | head -1 | cut -d= -f2-)
    port=$(grep -E '^runtime_port=' "$meta" | head -1 | cut -d= -f2-)
    echo "$base $mark env=${env:-?} port=${port:-?} commit=${commit:0:12}"
  else
    echo "$base $mark (no release.meta)"
  fi
  count=$((count + 1))
  [[ "$count" -ge "$LIMIT" ]] && break
done
echo "shown=$count"
