#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FIXTURE_REPO="$TMP_DIR/repo"
FAKE_BIN="$TMP_DIR/bin"
mkdir -p \
  "$FIXTURE_REPO/.git" \
  "$FIXTURE_REPO/.state/asdev-mcp" \
  "$FIXTURE_REPO/.state/asdev-supervisor" \
  "$FIXTURE_REPO/scripts/control-plane" \
  "$FIXTURE_REPO/reports" \
  "$FAKE_BIN"

cat > "$FAKE_BIN/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  rev-parse)
    if [ "${2:-}" = "--abbrev-ref" ]; then
      echo main
    else
      echo main
    fi
    ;;
  rev-list)
    echo 0
    ;;
  fetch|pull|checkout|branch|reset|diff|rebase|cherry-pick)
    ;;
  *)
    ;;
esac
SH

cat > "$FAKE_BIN/systemctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = "--user" ]; then
  shift
fi
case "${1:-}" in
  list-timers)
    cat <<'OUT'
asdev-github-sync.timer
asdev-agent-loop.timer
asdev-health-monitor.timer
asdev-mcp-monitor.timer
asdev-supervisor.timer
OUT
    ;;
  show)
    case "${3:-}" in
      --property=Result) echo success ;;
      *) echo active ;;
    esac
    ;;
  restart)
    ;;
  *)
    ;;
esac
SH

cat > "$FAKE_BIN/df" <<'SH'
#!/usr/bin/env bash
cat <<'OUT'
Filesystem Size Used Avail Use% Mounted on
/dev/fake 100G 50G 50G 50% /fixture
OUT
SH

cat > "$FAKE_BIN/free" <<'SH'
#!/usr/bin/env bash
cat <<'OUT'
              total        used        free      shared  buff/cache   available
Mem:            100          20          80           0           0          80
OUT
SH

cat > "$FAKE_BIN/ping" <<'SH'
#!/usr/bin/env bash
exit 0
SH

chmod +x "$FAKE_BIN/git" "$FAKE_BIN/systemctl" "$FAKE_BIN/df" "$FAKE_BIN/free" "$FAKE_BIN/ping"

# Simulate an older MCP state at the path the supervisor currently reads.
cat > "$FIXTURE_REPO/.state/asdev-mcp/latest.json" <<'JSON'
{"timestamp":"stale","mcp_service":"active"}
JSON

# Simulate the current MCP checker: it honors ASDEV_STATE_DIR inherited from
# the supervisor and records the real transport classification there.
cat > "$FIXTURE_REPO/scripts/control-plane/mcp-health-check-v2.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$ASDEV_STATE_DIR"
cat > "$ASDEV_STATE_DIR/latest.json" <<'JSON'
{"verdict":"FAIL","failure_class":"tls_failure","http_code":"000"}
JSON
exit 1
SH
chmod +x "$FIXTURE_REPO/scripts/control-plane/mcp-health-check-v2.sh"

set +e
PATH="$FAKE_BIN:$PATH" \
ASDEV_ENVIRONMENT="TEST" \
ASDEV_ROOT="$ROOT_DIR" \
ASDEV_REPO_DIR="$FIXTURE_REPO" \
ASDEV_STATE_DIR="$FIXTURE_REPO/.state/asdev-supervisor" \
ASDEV_REPORT_DIR="$FIXTURE_REPO/reports" \
bash "$ROOT_DIR/scripts/control-plane/asdev-supervisor.sh" \
  >"$TMP_DIR/supervisor.stdout" 2>"$TMP_DIR/supervisor.stderr"
status=$?
set -e

if [ "$status" -ne 1 ]; then
  echo "::error::Fixture must remain NO_GO because MCP is unhealthy (exit=$status)." >&2
  cat "$TMP_DIR/supervisor.stderr" >&2
  exit 1
fi

REPORT="$FIXTURE_REPO/reports/latest-supervisor.md"
if ! grep -qF 'FAIL [MCP-001] MCP endpoint unhealthy (verdict=FAIL failure=tls_failure)' "$REPORT"; then
  echo "::error::Supervisor did not consume the fresh MCP state from the child checker." >&2
  cat "$REPORT" >&2
  exit 1
fi

if grep -qF 'verdict=UNKNOWN failure=unknown' "$REPORT"; then
  echo "::error::Supervisor fell back to stale MCP state." >&2
  cat "$REPORT" >&2
  exit 1
fi

echo "Supervisor MCP state isolation regression passed."
