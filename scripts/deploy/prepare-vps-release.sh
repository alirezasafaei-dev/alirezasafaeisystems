#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="production"
APP_SLUG="my-portfolio"
SOURCE_DIR="$(pwd)"
OUT_ROOT="artifacts/releases"
RELEASE_ID=""
RUN_VERIFY=1
RUN_SMOKE=1
RUN_OWNERSHIP=1
RUN_NGINX_VALIDATE=1
RUN_HOSTING_SYNC=1

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --env <staging|production>   Target environment for artifact metadata (default: production)
  --app-slug <name>            App slug (default: my-portfolio)
  --source-dir <path>          Source project directory (default: cwd)
  --out-root <path>            Output root for artifacts (default: artifacts/releases)
  --release-id <id>            Release identifier (default: <UTC>-<commit>)
  --skip-verify                Skip pnpm run verify
  --skip-smoke                 Skip smoke e2e gate
  --skip-ownership             Skip ownership validation gate
  --skip-nginx-validate        Skip nginx co-hosting contract validation gate
  --skip-hosting-sync          Skip hosting sync gate
  -h, --help                   Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENVIRONMENT="${2:-}"
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
    --out-root)
      OUT_ROOT="${2:-}"
      shift 2
      ;;
    --release-id)
      RELEASE_ID="${2:-}"
      shift 2
      ;;
    --skip-verify)
      RUN_VERIFY=0
      shift
      ;;
    --skip-smoke)
      RUN_SMOKE=0
      shift
      ;;
    --skip-ownership)
      RUN_OWNERSHIP=0
      shift
      ;;
    --skip-nginx-validate)
      RUN_NGINX_VALIDATE=0
      shift
      ;;
    --skip-hosting-sync)
      RUN_HOSTING_SYNC=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[prepare-vps-release] unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
  echo "[prepare-vps-release] unsupported environment: $ENVIRONMENT" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "[prepare-vps-release] source dir not found: $SOURCE_DIR" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "[prepare-vps-release] git is required" >&2
  exit 1
fi
if ! command -v pnpm >/dev/null 2>&1; then
  echo "[prepare-vps-release] pnpm is required" >&2
  exit 1
fi
if ! command -v rsync >/dev/null 2>&1; then
  echo "[prepare-vps-release] rsync is required" >&2
  exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
  echo "[prepare-vps-release] tar is required" >&2
  exit 1
fi
if ! command -v sha256sum >/dev/null 2>&1; then
  echo "[prepare-vps-release] sha256sum is required" >&2
  exit 1
fi

SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
cd "$SOURCE_DIR"

GENERATED_SITEMAP_FILE="src/generated/sitemap-manifest.json"
RESTORE_GENERATED_SITEMAP=0
if git ls-files --error-unmatch "$GENERATED_SITEMAP_FILE" >/dev/null 2>&1; then
  if git diff --quiet -- "$GENERATED_SITEMAP_FILE" && git diff --cached --quiet -- "$GENERATED_SITEMAP_FILE"; then
    RESTORE_GENERATED_SITEMAP=1
  fi
fi

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
COMMIT_SHORT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
WORKTREE_STATE="dirty"
if git diff --quiet && git diff --cached --quiet; then
  WORKTREE_STATE="clean"
fi

if [[ -z "$RELEASE_ID" ]]; then
  RELEASE_ID="${TIMESTAMP}-${COMMIT_SHORT}"
fi

RELEASE_DIR="${OUT_ROOT}/${ENVIRONMENT}/${RELEASE_ID}"
LOG_DIR="${RELEASE_DIR}/logs"
mkdir -p "$LOG_DIR" docs/runtime

ARTIFACT_NAME="${APP_SLUG}-${ENVIRONMENT}-${RELEASE_ID}.tar.gz"
ARTIFACT_PATH="${RELEASE_DIR}/${ARTIFACT_NAME}"
ARTIFACT_SHA_PATH="${ARTIFACT_PATH}.sha256"
MANIFEST_PATH="${RELEASE_DIR}/manifest.txt"
REPORT_PATH="docs/runtime/VPS_DEPLOY_PREP_${TIMESTAMP}.md"

VERIFY_STATUS="skipped"
SMOKE_STATUS="skipped"
OWNERSHIP_STATUS="skipped"
NGINX_STATUS="skipped"
HOSTING_SYNC_STATUS="skipped"
OVERALL_STATUS="pass"

run_gate() {
  local gate_name="$1"
  local command="$2"
  local log_file="$3"
  local required="$4"

  set +e
  bash -lc "$command" >"$log_file" 2>&1
  local ec=$?
  set -e

  if [[ "$ec" -eq 0 ]]; then
    echo "[prepare-vps-release] ${gate_name}: pass"
    return 0
  fi

  echo "[prepare-vps-release] ${gate_name}: fail (log: $log_file)" >&2
  if [[ "$required" == "1" ]]; then
    OVERALL_STATUS="fail"
  fi
  return 1
}

if [[ "$RUN_VERIFY" == "1" ]]; then
  if run_gate "verify" "pnpm -s run verify" "${LOG_DIR}/verify.log" 1; then
    VERIFY_STATUS="pass"
  else
    VERIFY_STATUS="fail"
  fi
fi

if [[ "$RUN_SMOKE" == "1" ]]; then
  SMOKE_CMD='PORT=3100 pnpm run start >/tmp/alirezasafaeisystems-vps-prepare-smoke-server.log 2>&1 & srv=$!; for i in {1..60}; do code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3100/ || true); if [[ "$code" != "000" ]]; then break; fi; sleep 1; done; PLAYWRIGHT_DISABLE_WEBSERVER=true PLAYWRIGHT_BASE_URL=http://127.0.0.1:3100 pnpm -s run test:e2e:smoke; ec=$?; kill $srv >/dev/null 2>&1 || true; wait $srv 2>/dev/null || true; exit $ec'
  if run_gate "smoke" "$SMOKE_CMD" "${LOG_DIR}/smoke.log" 1; then
    SMOKE_STATUS="pass"
  else
    SMOKE_STATUS="fail"
  fi
fi

if [[ "$RUN_OWNERSHIP" == "1" ]]; then
  if run_gate "ownership" "bash scripts/release/validate-ownership.sh docs/ONCALL_ESCALATION.md" "${LOG_DIR}/ownership.log" 1; then
    OWNERSHIP_STATUS="pass"
  else
    OWNERSHIP_STATUS="fail"
  fi
fi

if [[ "$RUN_NGINX_VALIDATE" == "1" ]]; then
  if run_gate "nginx-contract" "bash scripts/deploy/validate-cohosting-config.sh" "${LOG_DIR}/nginx-contract.log" 1; then
    NGINX_STATUS="pass"
  else
    NGINX_STATUS="fail"
  fi
fi

if [[ "$RUN_HOSTING_SYNC" == "1" ]]; then
  if run_gate "hosting-sync" "bash scripts/deploy/check-hosting-sync.sh" "${LOG_DIR}/hosting-sync.log" 1; then
    HOSTING_SYNC_STATUS="pass"
  else
    HOSTING_SYNC_STATUS="fail"
  fi
fi

STAGE_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

rsync -a --delete \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'node_modules' \
  --exclude '.next' \
  --exclude 'coverage' \
  --exclude 'artifacts' \
  --exclude 'playwright-report' \
  --exclude 'test-results' \
  --exclude 'dev.log' \
  --exclude 'server.log' \
  --exclude '.env' \
  --exclude '.env.local' \
  --exclude '.env.*.local' \
  --exclude 'prisma/*.db' \
  --exclude 'prisma/*.db-journal' \
  "$SOURCE_DIR/" "$STAGE_DIR/source/"

if [[ -f "$SOURCE_DIR/.env.example" ]]; then
  cp "$SOURCE_DIR/.env.example" "$STAGE_DIR/source/.env.example"
fi

mkdir -p "$RELEASE_DIR"
tar -C "$STAGE_DIR/source" -czf "$ARTIFACT_PATH" .
sha256sum "$ARTIFACT_PATH" > "$ARTIFACT_SHA_PATH"
ARTIFACT_SIZE_BYTES="$(stat -c %s "$ARTIFACT_PATH")"

cat > "$MANIFEST_PATH" <<MANIFEST
release_id=${RELEASE_ID}
environment=${ENVIRONMENT}
app_slug=${APP_SLUG}
commit=${COMMIT_SHORT}
branch=${BRANCH_NAME}
worktree_state=${WORKTREE_STATE}
created_utc=${TIMESTAMP}
artifact=${ARTIFACT_PATH}
artifact_sha256_file=${ARTIFACT_SHA_PATH}
artifact_size_bytes=${ARTIFACT_SIZE_BYTES}
verify_status=${VERIFY_STATUS}
smoke_status=${SMOKE_STATUS}
ownership_status=${OWNERSHIP_STATUS}
nginx_contract_status=${NGINX_STATUS}
hosting_sync_status=${HOSTING_SYNC_STATUS}
overall_status=${OVERALL_STATUS}
MANIFEST

cat > "$REPORT_PATH" <<REPORT
# VPS Deploy Preparation Report (${TIMESTAMP})

- Environment: ${ENVIRONMENT}
- Release ID: ${RELEASE_ID}
- Commit: ${COMMIT_SHORT}
- Branch: ${BRANCH_NAME}
- Worktree state: ${WORKTREE_STATE}
- Artifact: ${ARTIFACT_PATH}
- SHA256 file: ${ARTIFACT_SHA_PATH}
- Manifest: ${MANIFEST_PATH}
- Artifact size (bytes): ${ARTIFACT_SIZE_BYTES}

## Gate Status
- verify: ${VERIFY_STATUS}
- smoke: ${SMOKE_STATUS}
- ownership: ${OWNERSHIP_STATUS}
- nginx contract: ${NGINX_STATUS}
- hosting sync: ${HOSTING_SYNC_STATUS}
- overall: ${OVERALL_STATUS}

## Gate Logs
- verify: ${LOG_DIR}/verify.log
- smoke: ${LOG_DIR}/smoke.log
- ownership: ${LOG_DIR}/ownership.log
- nginx contract: ${LOG_DIR}/nginx-contract.log
- hosting sync: ${LOG_DIR}/hosting-sync.log

## VPS Deploy Commands
\`\`\`bash
# 1) Upload artifact to VPS
scp ${ARTIFACT_PATH} <user>@<vps-host>:/tmp/

# 2) Extract artifact on VPS
ssh <user>@<vps-host> 'rm -rf /tmp/release-${RELEASE_ID} && mkdir -p /tmp/release-${RELEASE_ID} && tar -xzf /tmp/${ARTIFACT_NAME} -C /tmp/release-${RELEASE_ID}'

# 3) Run strict VPS preflight on server
ssh <user>@<vps-host> 'cd /tmp/release-${RELEASE_ID} && bash scripts/vps-preflight.sh --env ${ENVIRONMENT} --strict'

# 4) Deploy release
ssh <user>@<vps-host> 'cd /tmp/release-${RELEASE_ID} && bash ops/deploy/deploy.sh --env ${ENVIRONMENT} --source-dir /tmp/release-${RELEASE_ID}'
\`\`\`
REPORT

echo "[prepare-vps-release] report=${REPORT_PATH}"
echo "[prepare-vps-release] artifact=${ARTIFACT_PATH}"
echo "[prepare-vps-release] sha256=${ARTIFACT_SHA_PATH}"
echo "[prepare-vps-release] manifest=${MANIFEST_PATH}"

if [[ "$RESTORE_GENERATED_SITEMAP" == "1" ]]; then
  git restore --worktree -- "$GENERATED_SITEMAP_FILE" >/dev/null 2>&1 || true
fi

if [[ "$OVERALL_STATUS" != "pass" ]]; then
  echo "[prepare-vps-release] one or more required gates failed" >&2
  exit 1
fi

echo "[prepare-vps-release] ready for VPS deploy"
