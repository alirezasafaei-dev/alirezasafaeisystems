#!/usr/bin/env bash
# Rollback rehearsal — dry-run only. No symlink switch, no service restart.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
SITE="persiantoolbox"
ENV="staging"
COMMIT=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Dry-run rollback rehearsal for a site/environment.

Options:
  --site <id>           default: persiantoolbox
  --environment <env>   staging|production (default: staging)
  --commit <sha>        audit commit (default: HEAD of prepared source or repo)
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site) SITE="$2"; shift 2 ;;
    --environment) ENV="$2"; shift 2 ;;
    --commit) COMMIT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$COMMIT" ]]; then
  if [[ -d "$PROJECT_ROOT/sites/live/$SITE/.git" ]]; then
    COMMIT=$(git -C "$PROJECT_ROOT/sites/live/$SITE" rev-parse HEAD)
  else
    COMMIT=$(git -C "$PROJECT_ROOT" rev-parse HEAD)
  fi
fi

echo "========================================"
echo "  ROLLBACK REHEARSAL (DRY-RUN)"
echo "  site=$SITE env=$ENV commit=$COMMIT"
echo "========================================"

bash "$PROJECT_ROOT/scripts/deploy/asdev-rollback.sh" \
  --site "$SITE" \
  --environment "$ENV" \
  --commit "$COMMIT" \
  --check

bash "$PROJECT_ROOT/scripts/deploy/asdev-rollback.sh" \
  --site "$SITE" \
  --environment "$ENV" \
  --commit "$COMMIT" \
  --dry-run

echo "========================================"
echo "  REHEARSAL COMPLETE (no mutations)"
echo "========================================"
