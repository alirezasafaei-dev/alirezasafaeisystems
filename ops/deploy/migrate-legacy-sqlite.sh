#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="production"
BASE_DIR="${BASE_DIR:-/var/www/my-portfolio}"
PERSISTENT_DB_PATH="${PERSISTENT_DB_PATH:-/var/lib/my-portfolio/custom.db}"
APP_SLUG="${APP_SLUG:-my-portfolio}"

usage() {
  echo "Usage: $(basename "$0") [--env <staging|production>]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENVIRONMENT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[sqlite-relocation] unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
  echo "[sqlite-relocation] unsupported environment: $ENVIRONMENT" >&2
  exit 1
fi

ENV_FILE="$BASE_DIR/shared/env/$ENVIRONMENT.env"
CURRENT_LINK="$BASE_DIR/current/$ENVIRONMENT"
APP_NAME="$APP_SLUG-$ENVIRONMENT"
BACKUP_ROOT="$BASE_DIR/shared/backups/$ENVIRONMENT"
MIGRATION_MARKER="$BASE_DIR/shared/.legacy-sqlite-relocated-$ENVIRONMENT"
PORT="3003"
if [[ "$ENVIRONMENT" == "production" ]]; then
  PORT="3002"
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[sqlite-relocation] environment file not found: $ENV_FILE" >&2
  exit 1
fi

if [[ "$(grep -c '^DATABASE_URL=' "$ENV_FILE" || true)" != "1" ]]; then
  echo "[sqlite-relocation] expected exactly one DATABASE_URL entry" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${DATABASE_URL:-}" || "$DATABASE_URL" != file:* ]]; then
  echo "[sqlite-relocation] only SQLite file URLs are supported by this relocation" >&2
  exit 1
fi

# Absolute SQLite URLs already satisfy the deploy contract. This helper is a
# one-time bridge for the legacy relative configuration only.
if [[ "$DATABASE_URL" == file:/* ]]; then
  echo "[sqlite-relocation] DATABASE_URL is already absolute; no relocation required"
  exit 0
fi

if [[ -e "$MIGRATION_MARKER" ]]; then
  if [[ -f "$PERSISTENT_DB_PATH" ]]; then
    echo "[sqlite-relocation] relocation marker and persistent SQLite state verified; no migration required"
    exit 0
  fi
  echo "[sqlite-relocation] relocation marker exists but persistent SQLite state is missing; refusing unsafe continuation" >&2
  exit 1
fi

PREVIOUS_RELEASE="$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)"
if [[ -z "$PREVIOUS_RELEASE" || ! -d "$PREVIOUS_RELEASE/prisma" ]]; then
  echo "[sqlite-relocation] current release cannot be resolved safely" >&2
  exit 1
fi

LEGACY_SPEC="${DATABASE_URL#file:}"
LEGACY_SPEC="${LEGACY_SPEC%%\?*}"
if [[ -z "$LEGACY_SPEC" || "$LEGACY_SPEC" == /* ]]; then
  echo "[sqlite-relocation] legacy SQLite path is not a valid relative Prisma file URL" >&2
  exit 1
fi

# Prisma resolves a relative SQLite file URL from the directory containing the
# schema, which in this repository is <release>/prisma.
LEGACY_DB_PATH="$(realpath -m "$PREVIOUS_RELEASE/prisma/$LEGACY_SPEC")"
case "$LEGACY_DB_PATH" in
  "$PREVIOUS_RELEASE"/*) ;;
  *)
    echo "[sqlite-relocation] legacy SQLite path escapes the current release; refusing relocation" >&2
    exit 1
    ;;
esac

if [[ ! -f "$LEGACY_DB_PATH" ]]; then
  LEGACY_CANDIDATE_COUNT=0
  LEGACY_CANDIDATE_PATH=""
  for candidate in "$PREVIOUS_RELEASE/db/custom.db" "$PREVIOUS_RELEASE/prisma/dev.db" "$PREVIOUS_RELEASE/prisma/db/custom.db"; do
    if [[ -f "$candidate" ]]; then
      LEGACY_CANDIDATE_COUNT=$((LEGACY_CANDIDATE_COUNT + 1))
      LEGACY_CANDIDATE_PATH="$candidate"
    fi
  done

  if [[ "$LEGACY_CANDIDATE_COUNT" == "1" ]]; then
    LEGACY_DB_PATH="$LEGACY_CANDIDATE_PATH"
    echo "[sqlite-relocation] resolved legacy SQLite path via the only valid release candidate: $LEGACY_DB_PATH"
  elif [[ "$LEGACY_CANDIDATE_COUNT" -gt "1" ]]; then
    echo "[sqlite-relocation] multiple legacy SQLite candidates were found; refusing ambiguous relocation" >&2
    exit 1
  else
    echo "[sqlite-relocation] legacy SQLite database was not found at the resolved current-release path or supported release candidates" >&2
    exit 1
  fi
fi

if [[ -e "$PERSISTENT_DB_PATH" || -e "${PERSISTENT_DB_PATH}-wal" || -e "${PERSISTENT_DB_PATH}-shm" ]]; then
  echo "[sqlite-relocation] persistent destination already contains SQLite state; refusing to guess which copy is authoritative" >&2
  exit 1
fi

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$BACKUP_ROOT/legacy-relocation-$TIMESTAMP"
ENV_BACKUP="$BACKUP_DIR/$ENVIRONMENT.env.before-relocation"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
cp -a -- "$ENV_FILE" "$ENV_BACKUP"
cp -a -- "$LEGACY_DB_PATH" "$BACKUP_DIR/database.sqlite"
for suffix in -wal -shm; do
  if [[ -f "${LEGACY_DB_PATH}${suffix}" ]]; then
    cp -a -- "${LEGACY_DB_PATH}${suffix}" "$BACKUP_DIR/database.sqlite${suffix}"
  fi
done

APP_WAS_RUNNING=false
APP_PID="$(pm2 pid "$APP_NAME" 2>/dev/null | head -n 1 | tr -d '[:space:]' || true)"
if [[ "$APP_PID" =~ ^[1-9][0-9]*$ ]]; then
  APP_WAS_RUNNING=true
fi

ENV_UPDATED=false
PERSISTENT_CREATED=false
RELOCATION_SUCCEEDED=false

rollback_relocation() {
  local original_status="$1"
  trap - EXIT

  if [[ "$ENV_UPDATED" == "true" || "$PERSISTENT_CREATED" == "true" ]]; then
    if [[ "$APP_WAS_RUNNING" == "true" ]]; then
      pm2 stop "$APP_NAME" >/dev/null 2>&1 || true
    fi

    if [[ "$ENV_UPDATED" == "true" ]]; then
      cp -a -- "$ENV_BACKUP" "$ENV_FILE" || true
    fi

    if [[ "$PERSISTENT_CREATED" == "true" ]]; then
      mkdir -p "$BACKUP_DIR/failed-persistent-copy" || true
      for path in "$PERSISTENT_DB_PATH" "${PERSISTENT_DB_PATH}-wal" "${PERSISTENT_DB_PATH}-shm"; do
        if [[ -e "$path" ]]; then
          mv -- "$path" "$BACKUP_DIR/failed-persistent-copy/" || true
        fi
      done
    fi
  fi

  if [[ "$APP_WAS_RUNNING" == "true" ]]; then
    pm2 restart "$APP_NAME" --update-env >/dev/null 2>&1 || true
  fi

  exit "$original_status"
}

trap 'status=$?; if [[ "$RELOCATION_SUCCEEDED" != "true" ]]; then rollback_relocation "$status"; fi' EXIT

if [[ "$APP_WAS_RUNNING" == "true" ]]; then
  pm2 stop "$APP_NAME"
fi

mkdir -p "$(dirname "$PERSISTENT_DB_PATH")"
cp -a -- "$LEGACY_DB_PATH" "$PERSISTENT_DB_PATH"
PERSISTENT_CREATED=true
for suffix in -wal -shm; do
  if [[ -f "${LEGACY_DB_PATH}${suffix}" ]]; then
    cp -a -- "${LEGACY_DB_PATH}${suffix}" "${PERSISTENT_DB_PATH}${suffix}"
  fi
done

ENV_TMP="$(mktemp "$ENV_FILE.tmp.XXXXXX")"
if ! awk -v replacement="DATABASE_URL=file:$PERSISTENT_DB_PATH" '
  BEGIN { count = 0 }
  /^DATABASE_URL=/ { print replacement; count += 1; next }
  { print }
  END { if (count != 1) exit 42 }
' "$ENV_FILE" > "$ENV_TMP"; then
  rm -f -- "$ENV_TMP"
  echo "[sqlite-relocation] failed to rewrite DATABASE_URL atomically" >&2
  exit 1
fi
chmod --reference="$ENV_FILE" "$ENV_TMP"
mv -- "$ENV_TMP" "$ENV_FILE"
ENV_UPDATED=true
export DATABASE_URL="file:$PERSISTENT_DB_PATH"

if [[ "$APP_WAS_RUNNING" == "true" ]]; then
  pm2 restart "$APP_NAME" --update-env

  HEALTHY=false
  for attempt in {1..20}; do
    if curl -fsS "http://127.0.0.1:$PORT/api/ready" >/dev/null 2>&1; then
      HEALTHY=true
      break
    fi
    sleep 2
  done

  if [[ "$HEALTHY" != "true" ]]; then
    echo "[sqlite-relocation] previous application did not become healthy on persistent SQLite; rolling back relocation" >&2
    exit 1
  fi
fi

touch "$MIGRATION_MARKER"
chmod 600 "$MIGRATION_MARKER"
RELOCATION_SUCCEEDED=true
trap - EXIT

echo "[sqlite-relocation] legacy SQLite state copied to persistent storage; legacy source preserved"
echo "[sqlite-relocation] rollback snapshot: $BACKUP_DIR"
