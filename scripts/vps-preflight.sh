#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="production"
BASE_DIR="/var/www/my-portfolio"
APP_SLUG="my-portfolio"
STRICT=false
ROOT_DIR=""
SKIP_RUNTIME_CHECKS=false

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --env <staging|production>  Target environment (default: production)
  --base-dir <path>           Base deployment directory (default: /var/www/my-portfolio)
  --root-dir <path>           Root directory for co-hosting sync checks (default: dirname(base-dir))
  --app-slug <name>           App slug prefix for PM2 process names (default: my-portfolio)
  --skip-runtime-checks       Skip pm2/readiness runtime checks (safe for pre-deploy windows)
  --strict                    Treat warnings as errors
  -h, --help                  Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENVIRONMENT="${2:-}"
      shift 2
      ;;
    --base-dir)
      BASE_DIR="${2:-}"
      shift 2
      ;;
    --root-dir)
      ROOT_DIR="${2:-}"
      shift 2
      ;;
    --app-slug)
      APP_SLUG="${2:-}"
      shift 2
      ;;
    --skip-runtime-checks)
      SKIP_RUNTIME_CHECKS=true
      shift
      ;;
    --strict)
      STRICT=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[vps-preflight] unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
  echo "[vps-preflight] unsupported environment: $ENVIRONMENT" >&2
  exit 1
fi

if [[ -z "$ROOT_DIR" ]]; then
  ROOT_DIR="$(dirname "$BASE_DIR")"
fi

REQUIRED=(node pnpm pm2 rsync nginx curl)
WARN_COUNT=0
FAIL_COUNT=0

warn() {
  echo "[vps-preflight] WARN $*"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo "[vps-preflight] ERROR $*" >&2
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

echo "[vps-preflight] environment=${ENVIRONMENT} base_dir=${BASE_DIR} root_dir=${ROOT_DIR} strict=${STRICT} skip_runtime_checks=${SKIP_RUNTIME_CHECKS}"

for c in "${REQUIRED[@]}"; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "[vps-preflight] found command: $c"
  else
    fail "missing command: $c"
  fi
done

ENV_FILE="${BASE_DIR}/shared/env/${ENVIRONMENT}.env"
RELEASES_DIR="${BASE_DIR}/releases/${ENVIRONMENT}"
LOG_DIR="${BASE_DIR}/shared/logs"
CURRENT_DIR="${BASE_DIR}/current"
APP_NAME="${APP_SLUG}-${ENVIRONMENT}"
PORT="3003"
if [[ "$ENVIRONMENT" == "production" ]]; then
  PORT="3002"
fi

for d in "$RELEASES_DIR" "$LOG_DIR" "$CURRENT_DIR"; do
  if [[ -d "$d" ]]; then
    echo "[vps-preflight] found directory: $d"
  else
    warn "missing directory: $d"
  fi
done

if [[ -f "$ENV_FILE" ]]; then
  echo "[vps-preflight] found env file: $ENV_FILE"
  if rg -n 'replace-with-|TODO_|CHANGEME|example' "$ENV_FILE" >/dev/null 2>&1; then
    warn "env file may contain placeholders: $ENV_FILE"
  fi
else
  fail "missing env file: $ENV_FILE"
fi

if [[ -d "$RELEASES_DIR" && ! -w "$RELEASES_DIR" ]]; then
  warn "deploy user cannot write releases dir: $RELEASES_DIR"
fi
if [[ -d "$LOG_DIR" && ! -w "$LOG_DIR" ]]; then
  warn "deploy user cannot write logs dir: $LOG_DIR"
fi

if bash scripts/deploy/validate-cohosting-config.sh >/dev/null 2>&1; then
  echo "[vps-preflight] nginx co-hosting contract check: pass"
else
  fail "nginx co-hosting contract check failed"
fi

if [[ "$STRICT" == "true" ]]; then
  if bash scripts/deploy/check-hosting-sync.sh --strict --root-dir "$ROOT_DIR" >/dev/null 2>&1; then
    echo "[vps-preflight] hosting sync check: pass (strict)"
  else
    fail "hosting sync check failed (strict)"
  fi
else
  if bash scripts/deploy/check-hosting-sync.sh --root-dir "$ROOT_DIR" >/dev/null 2>&1; then
    echo "[vps-preflight] hosting sync check: pass"
  else
    warn "hosting sync check reported issues"
  fi
fi

if [[ "$SKIP_RUNTIME_CHECKS" == "true" ]]; then
  echo "[vps-preflight] runtime checks skipped (--skip-runtime-checks)"
else
  if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
    echo "[vps-preflight] pm2 process exists: $APP_NAME"
  else
    warn "pm2 process not found yet: $APP_NAME"
  fi

  if curl -fsS "http://127.0.0.1:${PORT}/api/ready" >/dev/null 2>&1; then
    echo "[vps-preflight] local readiness endpoint is reachable on :${PORT}"
  else
    warn "local readiness endpoint is not reachable on :${PORT}"
  fi
fi

echo "[vps-preflight] summary fails=${FAIL_COUNT} warns=${WARN_COUNT}"

if [[ "$STRICT" == "true" && "$WARN_COUNT" -gt 0 ]]; then
  echo "[vps-preflight] strict mode enabled and warnings detected" >&2
  exit 1
fi

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi

echo "[vps-preflight] preflight ok"
