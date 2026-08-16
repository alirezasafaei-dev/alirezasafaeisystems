#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin" "$TMP_DIR/state" "$TMP_DIR/reports"

cat > "$TMP_DIR/bin/curl" <<'FAKE_CURL'
#!/usr/bin/env bash
printf '000'
exit 6
FAKE_CURL
chmod +x "$TMP_DIR/bin/curl"

set +e
PATH="$TMP_DIR/bin:$PATH" \
ASDEV_REPO_DIR="$TMP_DIR/repo" \
ASDEV_STATE_DIR="$TMP_DIR/state" \
ASDEV_REPORT_DIR="$TMP_DIR/reports" \
ASDEV_MCP_URL="https://mcp.invalid.example/sse/" \
bash "$ROOT_DIR/scripts/control-plane/mcp-health-check-v2.sh" >"$TMP_DIR/output.log" 2>&1
status=$?
set -e

if [ "$status" -ne 1 ]; then
  echo "Expected MCP health check to fail for DNS error; got exit $status" >&2
  cat "$TMP_DIR/output.log" >&2
  exit 1
fi

STATE_FILE="$TMP_DIR/state/latest.json"
if [ ! -f "$STATE_FILE" ]; then
  echo "Expected MCP health check to write structured state" >&2
  cat "$TMP_DIR/output.log" >&2
  exit 1
fi

grep -q '"curl_exit_code": 6' "$STATE_FILE" || {
  echo "Expected curl exit code 6 to be preserved" >&2
  cat "$STATE_FILE" >&2
  exit 1
}

grep -q '"failure_class": "dns_failure"' "$STATE_FILE" || {
  echo "Expected DNS failure classification" >&2
  cat "$STATE_FILE" >&2
  exit 1
}

echo "MCP curl-exit regression passed."
