#!/usr/bin/env bash
# Rollback rehearsal: validates previous_release exists and prints plan.
# Default dry-run only. Never swaps symlink unless --execute + production phrase.
set -euo pipefail
SITE_ROOT="${ASDEV_SITE_ROOT:-/srv/asdev/sites/persiantoolbox}"
EXECUTE=false
PHRASE="${APPROVE_PHRASE:-}"
usage() {
  cat <<EOF
Usage: $(basename "$0") [--site-root PATH] [--dry-run|--execute] [--approve-phrase PHRASE]

Default: dry-run (safe).
--execute requires APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY for production roots.
EOF
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --site-root) SITE_ROOT="$2"; shift 2 ;;
    --dry-run) EXECUTE=false; shift ;;
    --execute) EXECUTE=true; shift ;;
    --approve-phrase) PHRASE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown $1" >&2; exit 1 ;;
  esac
done
echo "========================================"
echo "  ROLLBACK REHEARSE"
echo "  root=$SITE_ROOT mode=$([ "$EXECUTE" = true ] && echo EXECUTE || echo DRY_RUN)"
echo "========================================"
if [[ ! -e "$SITE_ROOT/current" ]]; then
  echo "FAIL: no current symlink"
  exit 1
fi
cur=$(readlink -f "$SITE_ROOT/current")
meta="$cur/release.meta"
prev=""
if [[ -f "$meta" ]]; then
  prev=$(grep -E '^previous_release=' "$meta" | head -1 | cut -d= -f2- || true)
fi
echo "current=$cur"
echo "previous_release_field=${prev:-EMPTY}"
# also detect second newest release dir
second=""
# shellcheck disable=SC2012
mapfile -t rels < <(ls -1dt "$SITE_ROOT/releases"/* 2>/dev/null | head -5)
if [[ "${#rels[@]}" -ge 2 ]]; then
  second="${rels[1]}"
  echo "second_newest_release=$second"
else
  echo "second_newest_release=NONE"
fi
if [[ -z "$prev" && -z "$second" ]]; then
  echo "RESULT=NO_ROLLBACK_TARGET (first deploy posture)"
  echo "RECOVERY=redeploy same pin with production phrase OR emergency stop pid"
  exit 0
fi
target="${prev:-}"
if [[ -n "$target" && ! -d "$SITE_ROOT/releases/$target" && ! -d "$target" ]]; then
  # try as basename under releases
  if [[ -d "$SITE_ROOT/releases/$target" ]]; then
    :
  else
    echo "WARN: previous_release path not found on disk"
  fi
fi
plan_target="${second:-$SITE_ROOT/releases/$prev}"
echo "plan_symlink_to=${plan_target}"
if [[ "$EXECUTE" != "true" ]]; then
  echo "DRY_RUN_OK — no symlink change"
  exit 0
fi
if [[ "$PHRASE" != "APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY" ]]; then
  echo "REFUSED: execute requires APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY"
  exit 2
fi
echo "EXECUTE not implemented in this helper — use asdev-rollback.sh with phrase"
exit 3
