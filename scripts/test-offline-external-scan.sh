#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

make_fixture() {
  local dir="$1"
  mkdir -p "$dir/src" "$dir/.next" "$dir/bin"
}

# Missing scanner must fail closed and must never print the clean-scan success line.
MISSING_FIXTURE="$TMP_DIR/missing"
make_fixture "$MISSING_FIXTURE"
set +e
(
  cd "$MISSING_FIXTURE"
  EXTERNAL_SCAN_RG_BIN="asdev-rg-missing-${RANDOM}-$$" \
    bash "$ROOT_DIR/scripts/offline-external-scan.sh"
) >"$TMP_DIR/missing.log" 2>&1
missing_status=$?
set -e

if [ "$missing_status" -eq 0 ]; then
  echo "::error::Offline external scan unexpectedly passed without a scanner." >&2
  cat "$TMP_DIR/missing.log" >&2
  exit 1
fi
if grep -qF 'No external runtime dependencies found!' "$TMP_DIR/missing.log"; then
  echo "::error::Offline external scan reported a clean result without a scanner." >&2
  exit 1
fi

# A scanner match must produce a blocking result.
MATCH_FIXTURE="$TMP_DIR/match"
make_fixture "$MATCH_FIXTURE"
cat > "$MATCH_FIXTURE/bin/fake-rg-match" <<'FAKE_MATCH'
#!/usr/bin/env bash
printf '%s\n' 'src/example.ts:1:fetch("https://forbidden.example")'
exit 0
FAKE_MATCH
chmod +x "$MATCH_FIXTURE/bin/fake-rg-match"
set +e
(
  cd "$MATCH_FIXTURE"
  EXTERNAL_SCAN_RG_BIN="$MATCH_FIXTURE/bin/fake-rg-match" \
    bash "$ROOT_DIR/scripts/offline-external-scan.sh"
) >"$TMP_DIR/match.log" 2>&1
match_status=$?
set -e

if [ "$match_status" -ne 1 ]; then
  echo "::error::Offline external scan did not block a scanner match (exit=$match_status)." >&2
  cat "$TMP_DIR/match.log" >&2
  exit 1
fi

# A verified no-match scanner result must still allow a clean fixture to pass.
CLEAN_FIXTURE="$TMP_DIR/clean"
make_fixture "$CLEAN_FIXTURE"
cat > "$CLEAN_FIXTURE/bin/fake-rg-clean" <<'FAKE_CLEAN'
#!/usr/bin/env bash
exit 1
FAKE_CLEAN
chmod +x "$CLEAN_FIXTURE/bin/fake-rg-clean"
(
  cd "$CLEAN_FIXTURE"
  EXTERNAL_SCAN_RG_BIN="$CLEAN_FIXTURE/bin/fake-rg-clean" \
    bash "$ROOT_DIR/scripts/offline-external-scan.sh"
) >"$TMP_DIR/clean.log" 2>&1

grep -qF 'No external runtime dependencies found!' "$TMP_DIR/clean.log" || {
  echo "::error::Offline external scan did not pass a verified clean fixture." >&2
  cat "$TMP_DIR/clean.log" >&2
  exit 1
}

# A scanner runtime error must not be converted into a clean result by legacy `|| true` call sites.
ERROR_FIXTURE="$TMP_DIR/error"
make_fixture "$ERROR_FIXTURE"
cat > "$ERROR_FIXTURE/bin/fake-rg-error" <<'FAKE_ERROR'
#!/usr/bin/env bash
exit 2
FAKE_ERROR
chmod +x "$ERROR_FIXTURE/bin/fake-rg-error"
set +e
(
  cd "$ERROR_FIXTURE"
  EXTERNAL_SCAN_RG_BIN="$ERROR_FIXTURE/bin/fake-rg-error" \
    bash "$ROOT_DIR/scripts/offline-external-scan.sh"
) >"$TMP_DIR/error.log" 2>&1
error_status=$?
set -e

if [ "$error_status" -eq 0 ]; then
  echo "::error::Offline external scan unexpectedly passed after a scanner runtime error." >&2
  cat "$TMP_DIR/error.log" >&2
  exit 1
fi
if grep -qF 'No external runtime dependencies found!' "$TMP_DIR/error.log"; then
  echo "::error::Scanner runtime error was reported as a clean scan." >&2
  exit 1
fi

echo "Offline external scan fail-closed regression passed."
