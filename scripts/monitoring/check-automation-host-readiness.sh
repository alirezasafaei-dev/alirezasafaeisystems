#!/usr/bin/env bash
# Readiness checker for AUTOMATION_HOST (executor/orchestrator).
# Safe: local read-only inspection. No mutation. No secrets printed.
set -euo pipefail

PROJECT_ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
DRY_RUN=false
CHECK_MODE=false
ERRORS=0
WARNINGS=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Classify AUTOMATION_HOST executor readiness (read-only).

Optional:
  --project-root <path>   ASDEV checkout path (default: \$ASDEV_ROOT or /home/dev13/ASDEV)
  --dry-run               Print planned checks only
  --check                 Alias for --dry-run
  -h, --help              Show help

Classification:
  READY | DEGRADED_NON_BLOCKING | DEGRADED_BLOCKING | NOT_READY
EOF
}

log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
warn() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN: $*"; WARNINGS=$((WARNINGS + 1)); }
err()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }

require_cmd() {
  local cmd="$1" critical="${2:-true}"
  if [[ "$DRY_RUN" == "true" || "$CHECK_MODE" == "true" ]]; then
    log "[DRY RUN] Would check command: $cmd"
    return 0
  fi
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "tool present: $cmd"
  else
    if [[ "$critical" == "true" ]]; then
      err "missing critical tool: $cmd"
    else
      warn "missing optional tool: $cmd"
    fi
  fi
}

check_repo() {
  if [[ "$DRY_RUN" == "true" || "$CHECK_MODE" == "true" ]]; then
    log "[DRY RUN] Would inspect ASDEV repo at $PROJECT_ROOT"
    return 0
  fi
  if [[ ! -d "$PROJECT_ROOT/.git" && ! -L "$PROJECT_ROOT" ]]; then
    err "ASDEV path missing or not a git worktree: $PROJECT_ROOT"
    return
  fi
  if [[ ! -d "$PROJECT_ROOT/.git" && -L "$PROJECT_ROOT" ]]; then
    local target
    target=$(readlink -f "$PROJECT_ROOT" 2>/dev/null || true)
    if [[ -z "$target" || ! -d "$target/.git" ]]; then
      err "ASDEV symlink does not resolve to a git repo"
      return
    fi
  fi
  ok "ASDEV repo path resolvable"
  if [[ -f "$PROJECT_ROOT/deploy/registry.tsv" ]]; then
    ok "deploy registry present"
  else
    err "deploy registry missing"
  fi
  if [[ -x "$PROJECT_ROOT/scripts/deploy/asdev-deploy.sh" || -f "$PROJECT_ROOT/scripts/deploy/asdev-deploy.sh" ]]; then
    ok "deploy scripts present"
  else
    err "deploy scripts missing"
  fi
}

check_disk_memory() {
  if [[ "$DRY_RUN" == "true" || "$CHECK_MODE" == "true" ]]; then
    log "[DRY RUN] Would check disk/memory"
    return 0
  fi
  local avail_mb
  avail_mb=$(df -k / | tail -1 | awk '{print int($4/1024)}')
  if [[ "$avail_mb" -lt 1024 ]]; then
    err "low free disk: ${avail_mb}MB"
  elif [[ "$avail_mb" -lt 5120 ]]; then
    warn "disk free under 5GB: ${avail_mb}MB"
  else
    ok "disk free: ${avail_mb}MB"
  fi
  if command -v free >/dev/null 2>&1; then
    local avail_mem_mb
    avail_mem_mb=$(free -m | awk '/^Mem:/ {print $7}')
    if [[ "${avail_mem_mb:-0}" -lt 512 ]]; then
      warn "low available memory: ${avail_mem_mb}MB"
    else
      ok "memory available: ${avail_mem_mb}MB"
    fi
  fi
}

check_pm2_docker() {
  if [[ "$DRY_RUN" == "true" || "$CHECK_MODE" == "true" ]]; then
    log "[DRY RUN] Would inspect PM2/Docker status"
    return 0
  fi
  if command -v pm2 >/dev/null 2>&1; then
    local count
    count=$(pm2 jlist 2>/dev/null | command -p python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d))' 2>/dev/null || echo "unknown")
    if [[ "$count" == "0" ]]; then
      warn "PM2 idle (0 processes) — non-blocking if no ASDEV ecosystem configured"
    else
      ok "PM2 process count: $count"
    fi
  else
    warn "pm2 not installed (optional)"
  fi
  if command -v docker >/dev/null 2>&1; then
    local unhealthy
    unhealthy=$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null | wc -l | tr -d ' ')
    if [[ "${unhealthy:-0}" -gt 0 ]]; then
      warn "docker unhealthy containers: $unhealthy (classify before repair)"
    else
      ok "no unhealthy docker containers running"
    fi
  else
    warn "docker not installed (optional for executor)"
  fi
}

classify() {
  if [[ "$DRY_RUN" == "true" || "$CHECK_MODE" == "true" ]]; then
    echo "CLASSIFICATION=DRY_RUN"
    return 0
  fi
  local class
  if [[ $ERRORS -gt 0 ]]; then
    class="NOT_READY"
  elif [[ $WARNINGS -gt 0 ]]; then
    class="DEGRADED_NON_BLOCKING"
  else
    class="READY"
  fi
  # Missing critical tools already increment ERRORS → NOT_READY.
  # Empty PM2 / no runner are warnings only.
  echo "CLASSIFICATION=$class"
  echo "ERRORS=$ERRORS"
  echo "WARNINGS=$WARNINGS"
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-root) PROJECT_ROOT="$2"; shift 2 ;;
      --dry-run)      DRY_RUN=true; shift ;;
      --check)        CHECK_MODE=true; shift ;;
      -h|--help)      usage; exit 0 ;;
      *)              err "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  echo "========================================"
  echo "  AUTOMATION_HOST READINESS"
  echo "========================================"

  require_cmd git true
  require_cmd bash true
  require_cmd ssh true
  require_cmd node true
  require_cmd pnpm true
  require_cmd curl true
  require_cmd rsync true
  require_cmd docker false
  require_cmd pm2 false

  check_repo
  check_disk_memory
  check_pm2_docker

  if [[ "$DRY_RUN" != "true" && "$CHECK_MODE" != "true" ]]; then
    if pgrep -af 'Runner.Listener|actions.runner' >/dev/null 2>&1; then
      ok "GitHub Actions runner process present"
    else
      warn "No GitHub Actions self-hosted runner (not required for local executor path)"
    fi
  else
    log "[DRY RUN] Would check GitHub Actions runner process"
  fi

  echo "========================================"
  classify
  if [[ $ERRORS -gt 0 && "$DRY_RUN" != "true" && "$CHECK_MODE" != "true" ]]; then
    exit 1
  fi
}

main "$@"
