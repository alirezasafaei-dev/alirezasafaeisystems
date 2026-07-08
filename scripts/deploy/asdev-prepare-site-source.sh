#!/usr/bin/env bash
# Prepare local site source trees under sites/live/<site_id> for deploy dry-runs.
# Default is dry-run. Use --apply to clone/update. Never deploys. Never touches IRAN_PROD.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/asdev-common.sh
source "${SCRIPT_DIR}/lib/asdev-common.sh"
PROJECT_ROOT="$(asdev_project_root_from "$SCRIPT_DIR")"
SOURCE_MAP="${PROJECT_ROOT}/deploy/site-source-map.tsv"
REGISTRY="${PROJECT_ROOT}/deploy/registry.tsv"

SITE_NAME=""
DRY_RUN=true
APPLY=false
DEPTH="${ASDEV_CLONE_DEPTH:-1}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Prepare local source checkouts for deploy engine (sites/live/<site>).

Required:
  --site <name>     Registry site id (or 'all' for every map entry)

Optional:
  --apply           Clone/fetch into sites/live (default is dry-run)
  --dry-run         Preview only (default)
  --depth <n>       Shallow clone depth (default: 1)
  -h, --help        Show help

Env:
  ASDEV_SITES_ROOT  Override parent directory for checkouts
                    (default: <project>/sites/live)

Examples:
  $(basename "$0") --site persiantoolbox --dry-run
  $(basename "$0") --site persiantoolbox --apply
  $(basename "$0") --site all --apply
EOF
}

log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
warn() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN: $*"; }
err()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; exit 1; }

sites_root() {
  if [[ -n "${ASDEV_SITES_ROOT:-}" ]]; then
    printf '%s\n' "${ASDEV_SITES_ROOT%/}"
  else
    printf '%s\n' "${PROJECT_ROOT}/sites/live"
  fi
}

map_field() {
  local site="$1" col="$2"
  awk -F'\t' -v site="$site" -v col="$col" 'NR>1 && $1==site {print $col; exit}' "$SOURCE_MAP"
}

prepare_one() {
  local site="$1"
  local git_url branch target status
  git_url=$(map_field "$site" 2)
  branch=$(map_field "$site" 3)
  [[ -z "$git_url" ]] && err "Site '$site' not found in site-source-map.tsv"

  if ! grep -q "^${site}	" "$REGISTRY" 2>/dev/null; then
    warn "Site '$site' not in deploy/registry.tsv — still preparable from map"
  fi

  target="$(sites_root)/${site}"

  if [[ "$git_url" == "." ]]; then
    log "Site $site uses monorepo root (no clone)"
    log "  source: $PROJECT_ROOT"
    if [[ -f "${PROJECT_ROOT}/package.json" ]]; then
      ok "Mother repo source ready for $site"
    else
      warn "Mother repo package.json missing"
    fi
    return 0
  fi

  status="missing"
  if [[ -d "$target/.git" ]]; then
    status="git-checkout"
  elif [[ -d "$target" ]]; then
    status="partial-dir"
  fi

  log "Site: $site"
  log "  remote: $git_url"
  log "  branch: $branch"
  log "  target: $target"
  log "  status: $status"

  if [[ "$APPLY" != "true" ]]; then
    log "[DRY RUN] Would ensure directory $(sites_root)"
    if [[ "$status" == "git-checkout" ]]; then
      log "[DRY RUN] Would git -C target fetch --depth $DEPTH origin $branch && reset --hard origin/$branch"
    else
      log "[DRY RUN] Would git clone --depth $DEPTH --branch $branch $git_url $target"
    fi
    return 0
  fi

  mkdir -p "$(sites_root)"

  if [[ "$status" == "git-checkout" ]]; then
    log "Updating existing checkout..."
    git -C "$target" fetch --depth "$DEPTH" origin "$branch"
    git -C "$target" checkout "$branch"
    git -C "$target" reset --hard "origin/${branch}"
  elif [[ "$status" == "partial-dir" ]]; then
    err "Target exists but is not a git checkout: $target (move aside manually)"
  else
    log "Cloning shallow checkout..."
    git clone --depth "$DEPTH" --branch "$branch" "$git_url" "$target"
  fi

  if [[ -f "${target}/package.json" ]]; then
    ok "Source ready: $target"
  else
    warn "Checkout complete but package.json missing — verify repo layout"
  fi
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --site)    SITE_NAME="$2"; shift 2 ;;
      --apply)   APPLY=true; DRY_RUN=false; shift ;;
      --dry-run) APPLY=false; DRY_RUN=true; shift ;;
      --depth)   DEPTH="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *)         err "Unknown option: $1" ;;
    esac
  done

  [[ -z "$SITE_NAME" ]] && err "Missing required --site"
  [[ -f "$SOURCE_MAP" ]] || err "Missing source map: $SOURCE_MAP"

  echo "========================================"
  echo "  PREPARE SITE SOURCE"
  echo "  mode: $([[ "$APPLY" == "true" ]] && echo APPLY || echo DRY-RUN)"
  echo "========================================"

  if [[ "$SITE_NAME" == "all" ]]; then
    local site
    while IFS=$'\t' read -r site _rest; do
      [[ "$site" == "site_id" || -z "$site" ]] && continue
      prepare_one "$site"
      echo ""
    done < "$SOURCE_MAP"
  else
    prepare_one "$SITE_NAME"
  fi

  ok "Prepare complete"
}

main "$@"
