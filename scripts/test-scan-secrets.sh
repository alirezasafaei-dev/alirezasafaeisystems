#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

missing_rg="asdev-rg-missing-${RANDOM}-$$"
missing_git="asdev-git-missing-${RANDOM}-$$"

# Fail closed when neither the primary scanner nor the verified fallback exists.
if SCAN_SECRETS_RG_BIN="$missing_rg" \
   SCAN_SECRETS_GIT_BIN="$missing_git" \
   bash "$ROOT_DIR/scripts/scan-secrets.sh" >"$TMP_DIR/no-scanner.log" 2>&1; then
  echo "::error::Secret scan unexpectedly succeeded without any scanner." >&2
  exit 1
fi

if grep -qF 'Secret scan passed.' "$TMP_DIR/no-scanner.log"; then
  echo "::error::Secret scan reported success while every scanner was unavailable." >&2
  exit 1
fi

# Verify the git-grep fallback actually detects a tracked synthetic secret.
FIXTURE_REPO="$TMP_DIR/fixture-repo"
mkdir -p "$FIXTURE_REPO"
git -C "$FIXTURE_REPO" init -q
printf 'const token = "%s";\n' "synthetic-secret-fixture-123" > "$FIXTURE_REPO/app.js"
git -C "$FIXTURE_REPO" add app.js

set +e
SCAN_SECRETS_ROOT_DIR="$FIXTURE_REPO" \
SCAN_SECRETS_RG_BIN="$missing_rg" \
bash "$ROOT_DIR/scripts/scan-secrets.sh" >"$TMP_DIR/fallback-detect.log" 2>&1
fallback_status=$?
set -e

if [ "$fallback_status" -ne 1 ]; then
  echo "::error::git-grep fallback did not block a synthetic secret (exit=$fallback_status)." >&2
  cat "$TMP_DIR/fallback-detect.log" >&2
  exit 1
fi

# Verify the same fallback succeeds on a clean tracked repository.
printf 'const token = process.env.TOKEN;\n' > "$FIXTURE_REPO/app.js"
git -C "$FIXTURE_REPO" add app.js

SCAN_SECRETS_ROOT_DIR="$FIXTURE_REPO" \
SCAN_SECRETS_RG_BIN="$missing_rg" \
bash "$ROOT_DIR/scripts/scan-secrets.sh" >"$TMP_DIR/fallback-clean.log" 2>&1

grep -qF 'Secret scan passed' "$TMP_DIR/fallback-clean.log" || {
  echo "::error::git-grep fallback did not report a clean repository correctly." >&2
  cat "$TMP_DIR/fallback-clean.log" >&2
  exit 1
}

echo "Secret scan fallback regression passed."
