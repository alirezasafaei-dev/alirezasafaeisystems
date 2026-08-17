#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT=""
BASE_DIR="/var/www/my-portfolio"
SOURCE_DIR=""
RELEASE_ID=""
KEEP_RELEASES=3
APP_SLUG="my-portfolio"

usage() {
  cat <<USAGE
Usage: $(basename "$0") --env <staging|production> --source-dir <path> [options]

Required:
  --env <name>             Target environment (staging, production)
  --source-dir <path>      Extracted release source directory

Optional:
  --app-slug <name>        Logical app slug (default: my-portfolio)
  --base-dir <path>        Base directory on server (default: /var/www/my-portfolio)
  --release-id <id>        Release identifier (default: UTC timestamp)
  --keep-releases <n>      Number of old releases to keep per env (default: 3)
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
    --app-slug)
      APP_SLUG="${2:-}"
      shift 2
      ;;
    --source-dir)
      SOURCE_DIR="${2:-}"
      shift 2
      ;;
    --release-id)
      RELEASE_ID="${2:-}"
      shift 2
      ;;
    --keep-releases)
      KEEP_RELEASES="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[deploy] unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$ENVIRONMENT" || -z "$SOURCE_DIR" ]]; then
  usage
  exit 1
fi

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
  echo "[deploy] unsupported environment: $ENVIRONMENT" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "[deploy] source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

if [[ -z "$RELEASE_ID" ]]; then
  RELEASE_ID="$(date -u +%Y%m%dT%H%M%SZ)"
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "[deploy] rsync is required but not installed" >&2
  exit 1
fi
if ! command -v pm2 >/dev/null 2>&1; then
  echo "[deploy] pm2 is required but not installed" >&2
  exit 1
fi
if ! command -v node >/dev/null 2>&1; then
  echo "[deploy] node is required but not installed" >&2
  exit 1
fi
if ! command -v pnpm >/dev/null 2>&1; then
  echo "[deploy] pnpm is required but not installed" >&2
  exit 1
fi

SHARED_DIR="$BASE_DIR/shared"
ENV_DIR="$SHARED_DIR/env"
LOG_DIR="$SHARED_DIR/logs"
BACKUP_DIR="$BASE_DIR/shared/backups/$ENVIRONMENT"
RELEASES_DIR="$BASE_DIR/releases/$ENVIRONMENT"
CURRENT_LINK="$BASE_DIR/current/$ENVIRONMENT"
RELEASE_DIR="$RELEASES_DIR/$RELEASE_ID"
ENV_FILE="$ENV_DIR/$ENVIRONMENT.env"
APP_NAME="$APP_SLUG-$ENVIRONMENT"
PORT="3003"

if [[ "$ENVIRONMENT" == "production" ]]; then
  PORT="3002"
fi

mkdir -p "$ENV_DIR" "$LOG_DIR" "$BACKUP_DIR" "$RELEASES_DIR" "$BASE_DIR/current"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[deploy] environment file not found: $ENV_FILE" >&2
  exit 1
fi

mkdir -p "$RELEASE_DIR"
rsync -a --delete \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'node_modules' \
  --exclude 'coverage' \
  --exclude '.next/cache' \
  --exclude 'test-results' \
  "$SOURCE_DIR/" "$RELEASE_DIR/"

cd "$RELEASE_DIR"
pnpm install --frozen-lockfile
pnpm run db:generate

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

export NODE_ENV=production
export HOSTNAME=127.0.0.1
export PORT

if [[ "${DATABASE_URL:-}" != file:/* ]]; then
  echo "[deploy] DATABASE_URL must use an absolute SQLite file URL (file:/absolute/path.db)" >&2
  exit 1
fi
DB_PATH="${DATABASE_URL#file:}"
DB_PATH="${DB_PATH%%\?*}"
if [[ "$DB_PATH" != /* ]]; then
  echo "[deploy] DATABASE_URL must use an absolute SQLite file URL (file:/absolute/path.db)" >&2
  exit 1
fi
mkdir -p "$(dirname "$DB_PATH")"

# Build while the previous release is still serving traffic. Database mutation
# is deliberately delayed until the replacement application is ready to start.
pnpm run build

cat > ecosystem.config.cjs <<ECOSYSTEM
module.exports = {
  apps: [
    {
      name: '$APP_NAME',
      cwd: '$RELEASE_DIR',
      script: 'node',
      args: '.next/standalone/server.js',
      env_file: '$ENV_FILE',
      env: {
        NODE_ENV: 'production',
        HOSTNAME: '127.0.0.1',
        PORT: '$PORT'
      },
      max_restarts: 10,
      restart_delay: 3000,
      out_file: '$LOG_DIR/$APP_NAME.out.log',
      error_file: '$LOG_DIR/$APP_NAME.err.log',
      merge_logs: true,
      time: true
    }
  ]
};
ECOSYSTEM

PREVIOUS_RELEASE="$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)"
SNAPSHOT_DIR="$BACKUP_DIR/$RELEASE_ID"
APP_WAS_RUNNING=false
APP_PID="$(pm2 pid "$APP_NAME" 2>/dev/null | head -n 1 | tr -d '[:space:]' || true)"
if [[ "$APP_PID" =~ ^[1-9][0-9]*$ ]]; then
  APP_WAS_RUNNING=true
fi

if [[ "$APP_WAS_RUNNING" == "true" && ( -z "$PREVIOUS_RELEASE" || ! -f "$PREVIOUS_RELEASE/ecosystem.config.cjs" ) ]]; then
  echo "[deploy] previous running release cannot be resolved safely; refusing rollout" >&2
  exit 1
fi

snapshot_database() {
  rm -rf -- "$SNAPSHOT_DIR" || return 1
  mkdir -p "$SNAPSHOT_DIR" || return 1
  chmod 700 "$SNAPSHOT_DIR" || return 1

  if [[ -f "$DB_PATH" ]]; then
    cp -a -- "$DB_PATH" "$SNAPSHOT_DIR/database.sqlite" || return 1
    for suffix in -wal -shm; do
      if [[ -f "${DB_PATH}${suffix}" ]]; then
        cp -a -- "${DB_PATH}${suffix}" "$SNAPSHOT_DIR/database.sqlite${suffix}" || return 1
      fi
    done
  else
    : > "$SNAPSHOT_DIR/.database-absent" || return 1
  fi
}

restore_database_snapshot() {
  rm -f -- "$DB_PATH" "${DB_PATH}-wal" "${DB_PATH}-shm" || return 1

  if [[ -f "$SNAPSHOT_DIR/.database-absent" ]]; then
    return 0
  fi

  if [[ ! -f "$SNAPSHOT_DIR/database.sqlite" ]]; then
    echo "[deploy] database snapshot is incomplete; refusing silent recovery" >&2
    return 1
  fi

  cp -a -- "$SNAPSHOT_DIR/database.sqlite" "$DB_PATH" || return 1
  for suffix in -wal -shm; do
    if [[ -f "$SNAPSHOT_DIR/database.sqlite${suffix}" ]]; then
      cp -a -- "$SNAPSHOT_DIR/database.sqlite${suffix}" "${DB_PATH}${suffix}" || return 1
    fi
  done
}

restart_previous_app() {
  if [[ "$APP_WAS_RUNNING" == "true" ]]; then
    pm2 restart "$APP_NAME" --update-env || return 1
    pm2 save >/dev/null 2>&1 || true
  fi
}

rollback_previous_release() {
  if [[ "$APP_WAS_RUNNING" != "true" ]]; then
    echo "[deploy] no previously running application is available for rollback" >&2
    return 1
  fi
  if [[ -z "$PREVIOUS_RELEASE" || ! -f "$PREVIOUS_RELEASE/ecosystem.config.cjs" ]]; then
    echo "[deploy] previous release metadata is unavailable for rollback" >&2
    return 1
  fi

  pm2 delete "$APP_NAME" >/dev/null 2>&1 || true
  (
    cd "$PREVIOUS_RELEASE"
    pm2 start ecosystem.config.cjs --only "$APP_NAME" --update-env
  ) || return 1
  pm2 save >/dev/null 2>&1 || true
}

# Quiesce the old application only for the snapshot + migration window. With
# SQLite this avoids copying a live database/WAL set and makes recovery exact.
if [[ "$APP_WAS_RUNNING" == "true" ]]; then
  if ! pm2 stop "$APP_NAME"; then
    echo "[deploy] failed to quiesce previous application; migration not attempted" >&2
    exit 1
  fi
fi

if ! snapshot_database; then
  echo "[deploy] database snapshot failed; migration not attempted" >&2
  restart_previous_app || true
  exit 1
fi

echo "[deploy] database snapshot created for release $RELEASE_ID"

if ! pnpm exec prisma migrate deploy; then
  echo "[deploy] database migration failed; restoring pre-migration snapshot" >&2
  if ! restore_database_snapshot; then
    echo "[deploy] CRITICAL: database snapshot restore failed" >&2
  fi
  restart_previous_app || true
  exit 1
fi

if ! pnpm exec prisma migrate status; then
  echo "[deploy] migration status is not clean; restoring pre-migration snapshot" >&2
  if ! restore_database_snapshot; then
    echo "[deploy] CRITICAL: database snapshot restore failed" >&2
  fi
  restart_previous_app || true
  exit 1
fi

# Replace the stopped previous app only after migrations are verified.
pm2 delete "$APP_NAME" >/dev/null 2>&1 || true
if ! pm2 start ecosystem.config.cjs --only "$APP_NAME" --update-env; then
  echo "[deploy] new application failed to start; rolling back previous release" >&2
  rollback_previous_release || true
  exit 1
fi
pm2 save >/dev/null 2>&1 || true

HEALTHY=false
for attempt in {1..20}; do
  if curl -fsS "http://127.0.0.1:$PORT/api/ready" >/dev/null 2>&1; then
    echo "[deploy] health check passed for $ENVIRONMENT on port $PORT"
    HEALTHY=true
    break
  fi
  sleep 2
done

if [[ "$HEALTHY" != "true" ]]; then
  echo "[deploy] health check failed after 20 attempts; rolling back previous release" >&2
  rollback_previous_release || true
  exit 1
fi

# Publish the release symlink only after the new process is healthy.
ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

mapfile -t releases < <(ls -1dt "$RELEASES_DIR"/* 2>/dev/null || true)
if (( ${#releases[@]} > KEEP_RELEASES )); then
  for old_release in "${releases[@]:KEEP_RELEASES}"; do
    rm -rf "$old_release"
  done
fi

mapfile -t backups < <(ls -1dt "$BACKUP_DIR"/* 2>/dev/null || true)
if (( ${#backups[@]} > 5 )); then
  for old_backup in "${backups[@]:5}"; do
    rm -rf "$old_backup"
  done
fi

echo "[deploy] completed $ENVIRONMENT release $RELEASE_ID"
