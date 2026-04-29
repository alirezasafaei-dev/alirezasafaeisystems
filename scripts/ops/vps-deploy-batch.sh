#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
ENVIRONMENT="${ENVIRONMENT:-production}"
APPS="${APPS:-audit,portfolio,toolbox}"
ROOT="${ROOT:-/home/dev/Project_Me_All/Project_Me}"
RELEASE_PREFIX="${RELEASE_PREFIX:-batch}"

if [[ "${ENVIRONMENT}" != "production" && "${ENVIRONMENT}" != "staging" ]]; then
  echo "invalid ENVIRONMENT=${ENVIRONMENT}; expected production or staging" >&2
  exit 1
fi

if [[ ! -d "${ROOT}" ]]; then
  echo "project root not found: ${ROOT}" >&2
  exit 1
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

deploy_one() {
  local key="$1"
  local local_dir="$2"
  local remote_tmp="/tmp/release-${timestamp}-${RELEASE_PREFIX}-${key}"
  local remote_cmd=""

  case "$key" in
    audit)
      remote_cmd="cd '${remote_tmp}' && bash ops/deploy/deploy.sh --env '${ENVIRONMENT}' --source-dir '${remote_tmp}' --release-id '${timestamp}-${RELEASE_PREFIX}-audit'"
      ;;
    portfolio)
      remote_cmd="cd '${remote_tmp}' && bash ops/deploy/deploy.sh --env '${ENVIRONMENT}' --source-dir '${remote_tmp}' --release-id '${timestamp}-${RELEASE_PREFIX}-portfolio'"
      ;;
    toolbox)
      remote_cmd="cd '${remote_tmp}' && bash ops/deploy/deploy.sh --env '${ENVIRONMENT}' --source-dir '${remote_tmp}' --release-id '${timestamp}-${RELEASE_PREFIX}-toolbox'"
      ;;
    *)
      echo "unknown app key: ${key}" >&2
      return 1
      ;;
  esac

  echo "[batch-deploy] syncing ${key} -> ${remote_tmp}"
  rsync -az --delete \
    --exclude '.git' \
    --exclude '.github' \
    --exclude 'node_modules' \
    --exclude '.next/cache' \
    --exclude 'coverage' \
    --exclude 'test-results' \
    -e "ssh -i ${SSH_KEY} -o IdentitiesOnly=yes" \
    "${local_dir}/" "${SSH_HOST}:${remote_tmp}/"

  echo "[batch-deploy] deploying ${key} (${ENVIRONMENT})"
  ssh -i "${SSH_KEY}" -o IdentitiesOnly=yes "${SSH_HOST}" "${remote_cmd}"
}

IFS=',' read -r -a selected <<<"${APPS}"
for app in "${selected[@]}"; do
  case "${app}" in
    audit)
      deploy_one "audit" "${ROOT}/auditsystems"
      ;;
    portfolio)
      deploy_one "portfolio" "${ROOT}/alirezasafaeisystems"
      ;;
    toolbox)
      deploy_one "toolbox" "${ROOT}/persiantoolbox"
      ;;
    *)
      echo "invalid app in APPS=${APPS}: ${app}" >&2
      exit 1
      ;;
  esac
done

echo "[batch-deploy] done. env=${ENVIRONMENT} apps=${APPS}"
