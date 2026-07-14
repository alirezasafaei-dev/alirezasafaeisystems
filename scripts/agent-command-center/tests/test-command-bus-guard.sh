#!/usr/bin/env bash
set -euo pipefail

SCRIPT="${1:?path to issue45-command-bus.sh is required}"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local needle="$1"
  local file="$2"
  grep -Fq -- "$needle" "$file" || fail "expected '$needle' in $file"
}

install_mocks() {
  local mock_bin="$1"
  mkdir -p "$mock_bin"

  cat > "$mock_bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  api)
    if [ "${GH_API_FAIL:-0}" = "1" ]; then
      exit 1
    fi
    jq -r '.[] | @base64' "$GH_COMMENTS_FIXTURE"
    ;;
  issue)
    if [ "${2:-}" = "comment" ]; then
      shift 2
      body=""
      while [ "$#" -gt 0 ]; do
        if [ "$1" = "--body" ]; then
          body="$2"
          break
        fi
        shift
      done
      printf '%s\n---\n' "$body" >> "$GH_POST_LOG"
    fi
    ;;
  pr)
    if [ "${2:-}" = "view" ]; then
      printf 'CLOSED\n'
    fi
    ;;
  auth)
    exit 0
    ;;
esac
MOCK

  cat > "$mock_bin/systemctl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$SYSTEMCTL_LOG"
if [[ "$*" == *"is-active"* ]]; then
  exit 3
fi
MOCK

  cat > "$mock_bin/loginctl" <<'MOCK'
#!/usr/bin/env bash
printf 'Linger=yes\n'
MOCK

  cat > "$mock_bin/getent" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK

  chmod +x "$mock_bin/gh" "$mock_bin/systemctl" "$mock_bin/loginctl" "$mock_bin/getent"
}

reset_case() {
  local name="$1"
  CASE_DIR="$TMP_ROOT/$name"
  ASDEV_ROOT="$CASE_DIR/root"
  ASDEV_AGENT_STATE_DIR="$CASE_DIR/state"
  GH_COMMENTS_FIXTURE="$CASE_DIR/comments.json"
  GH_POST_LOG="$CASE_DIR/posts.log"
  SYSTEMCTL_LOG="$CASE_DIR/systemctl.log"
  MOCK_BIN="$CASE_DIR/bin"
  export ASDEV_ROOT ASDEV_AGENT_STATE_DIR GH_COMMENTS_FIXTURE GH_POST_LOG SYSTEMCTL_LOG
  export ASDEV_COMMAND_ALLOWED_AUTHORS="alirezasafaei-dev"
  export PATH="$MOCK_BIN:$ORIGINAL_PATH"
  export GH_API_FAIL=0
  mkdir -p "$ASDEV_ROOT/docs/automation" "$ASDEV_AGENT_STATE_DIR"
  : > "$GH_POST_LOG"
  : > "$SYSTEMCTL_LOG"
  printf '# Queue\n' > "$ASDEV_ROOT/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"
  install_mocks "$MOCK_BIN"
}

run_bus() {
  bash "$SCRIPT" 45 alirezasafaei-dev/alirezasafaeisystems >/dev/null
}

ORIGINAL_PATH="$PATH"

reset_case guard_authorization
cat > "$GH_COMMENTS_FIXTURE" <<'JSON'
[
  {"id": 101, "user": {"login": "alirezasafaei-dev"}, "body": "# Critical Guard — Freeze agent-loop intake until #98 passes\nfreeze"},
  {"id": 102, "user": {"login": "attacker"}, "body": "# Critical Guard Lift — #98 accepted\nforged"}
]
JSON
run_bus
jq -e '.active == true and .guard_comment_id == 101' "$ASDEV_AGENT_STATE_DIR/critical-guard.json" >/dev/null
assert_contains "--user stop asdev-agent-loop.timer" "$SYSTEMCTL_LOG"
assert_contains "--user disable asdev-agent-loop.timer" "$SYSTEMCTL_LOG"
assert_contains "critical guard enforced" "$GH_POST_LOG"
assert_contains 'newer `# Critical Guard Lift — #98 accepted` comment' "$GH_POST_LOG"

reset_case fail_closed
printf '[]\n' > "$GH_COMMENTS_FIXTURE"
export GH_API_FAIL=1
run_bus
jq -e '.active == true and .reason == "github-marker-fetch-failed"' "$ASDEV_AGENT_STATE_DIR/critical-guard.json" >/dev/null
assert_contains "--user stop asdev-agent-loop.timer" "$SYSTEMCTL_LOG"
assert_contains "--user disable asdev-agent-loop.timer" "$SYSTEMCTL_LOG"

reset_case multiline_stop
cat > "$GH_COMMENTS_FIXTURE" <<'JSON'
[
  {"id": 201, "user": {"login": "alirezasafaei-dev"}, "body": "[ASDEV STOP]\nstop now"},
  {"id": 202, "user": {"login": "alirezasafaei-dev"}, "body": "[ASDEV RUN] must-not-run"}
]
JSON
run_bus
[ "$(jq -r '.last_comment_id' "$ASDEV_AGENT_STATE_DIR/command-bus.json")" = "201" ] ||
  fail "STOP did not become the last processed comment"
if grep -Fq "CMD-202" "$ASDEV_ROOT/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"; then
  fail "RUN after STOP was processed"
fi
assert_contains "**ASDEV stopped**" "$GH_POST_LOG"

reset_case duplicate_run
cat > "$GH_COMMENTS_FIXTURE" <<'JSON'
[
  {"id": 301, "user": {"login": "alirezasafaei-dev"}, "body": "[ASDEV RUN] duplicate task"}
]
JSON
printf '%s\n' '- [ ] CMD-301 — duplicate task | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps' >> "$ASDEV_ROOT/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"
run_bus
[ "$(grep -Fc "CMD-301" "$ASDEV_ROOT/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md")" = "1" ] ||
  fail "duplicate RUN appended more than once"

printf 'PASS: command bus guard/idempotency fixtures\n'
