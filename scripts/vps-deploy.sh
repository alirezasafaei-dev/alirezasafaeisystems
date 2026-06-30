#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$PROJECT_DIR/../../.." && pwd)"
PROJECT_KEY="alirezasafaeisystems"

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") prepare
  $(basename "$0") sync-env [local-env-file] [production|staging]
  $(basename "$0") deploy [production|staging]
  $(basename "$0") status
USAGE
}

command="${1:-help}"

case "$command" in
  prepare)
    exec "$ROOT_DIR/scripts/deploy-vps.sh" prepare "$PROJECT_KEY"
    ;;
  sync-env)
    exec "$ROOT_DIR/scripts/deploy-vps.sh" sync-env "$PROJECT_KEY" "${2:-$PROJECT_DIR/.env}" "${3:-production}"
    ;;
  deploy)
    exec "$ROOT_DIR/scripts/deploy-vps.sh" deploy "$PROJECT_KEY" "${2:-production}"
    ;;
  status)
    exec "$ROOT_DIR/scripts/deploy-vps.sh" status
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "[portfolio-vps] unknown command: $command" >&2
    usage
    exit 1
    ;;
esac
