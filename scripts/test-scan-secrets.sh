#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

missing_scanner="asdev-rg-missing-${RANDOM}-$$"

if SCAN_SECRETS_RG_BIN="$missing_scanner" bash "$ROOT_DIR/scripts/scan-secrets.sh" >"$TMP_OUT" 2>&1; then
  echo "::error::Secret scan unexpectedly succeeded without its scanner dependency."
  exit 1
fi

if grep -qF 'Secret scan passed.' "$TMP_OUT"; then
  echo "::error::Secret scan reported success while the scanner dependency was missing."
  exit 1
fi

if ! grep -qF 'Secret scan unavailable: required scanner' "$TMP_OUT"; then
  echo "::error::Secret scan did not report the missing scanner dependency clearly."
  exit 1
fi

echo "Secret scan missing-dependency regression passed."
