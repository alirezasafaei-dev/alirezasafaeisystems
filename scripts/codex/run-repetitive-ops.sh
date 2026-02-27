#!/usr/bin/env bash
set -euo pipefail

REPO="parsairaniiidev/alirezasafaeisystems"
AUTO_CLOSE_DEPENDABOT=false
LIMIT=20

usage() {
  cat <<'USAGE'
Usage: scripts/codex/run-repetitive-ops.sh [options]

Options:
  --repo <owner/name>        GitHub repository (default: parsairaniiidev/alirezasafaeisystems)
  --limit <n>                Number of PRs/workflow runs to inspect (default: 20)
  --close-dependabot         Close open dependabot PRs with a standard comment
  -h, --help                 Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      shift 2
      ;;
    --close-dependabot)
      AUTO_CLOSE_DEPENDABOT=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ops-maintain] unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

echo "=========================================="
echo "Repetitive Ops Maintenance"
echo "=========================================="
echo "repo=$REPO"
echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo
echo "[1/4] Recent Deploy VPS runs"
gh run list \
  -R "$REPO" \
  --workflow "Deploy VPS" \
  --limit "$LIMIT" \
  --json databaseId,status,conclusion,headSha,event,url \
  | jq -r '.[] | "\(.databaseId)\t\(.event)\t\(.status)\t\(.conclusion // "-")\t\(.headSha)\t\(.url)"'

echo
echo "[2/4] Domain health checks"
check_url() {
  local url="$1"
  local code
  code="$(curl --connect-timeout 10 --max-time 30 -sS -o /tmp/ops-maintain-last.json -w '%{http_code}' "$url" || true)"
  echo "  - ${url} => ${code}"
  if [[ "$code" != "200" ]]; then
    echo "    body: $(cat /tmp/ops-maintain-last.json 2>/dev/null || echo '<none>')"
  fi
}

check_url "https://alirezasafaeisystems.ir/api/ready"
check_url "https://persiantoolbox.ir/api/health"

echo
echo "[3/4] Open PR queue"
gh pr list \
  -R "$REPO" \
  --state open \
  --limit "$LIMIT" \
  --json number,title,author,headRefName,baseRefName,url \
  | jq -r '.[] | "#\(.number)\t\(.author.login)\t\(.headRefName)->\(.baseRefName)\t\(.title)\t\(.url)"'

if [[ "$AUTO_CLOSE_DEPENDABOT" == "true" ]]; then
  echo
  echo "[4/4] Closing open dependabot PRs"
  mapfile -t prs < <(
    gh pr list \
      -R "$REPO" \
      --state open \
      --limit "$LIMIT" \
      --json number,author \
      | jq -r '.[] | select(.author.login=="app/dependabot") | .number'
  )

  if [[ "${#prs[@]}" -eq 0 ]]; then
    echo "  - no open dependabot PR found"
  else
    for pr in "${prs[@]}"; do
      gh pr close "$pr" -R "$REPO" --comment "Closing for repository stabilization after production deploy. Reopen in a curated dependency batch."
      echo "  - closed #$pr"
    done
  fi
else
  echo
  echo "[4/4] Dependabot close step skipped (use --close-dependabot to enable)"
fi

echo
echo "[ops-maintain] done"
