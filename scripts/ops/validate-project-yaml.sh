#!/usr/bin/env bash
# Validate project.yaml presence and required keys (no external deps).
set -euo pipefail
ROOT=""
usage() { echo "Usage: $0 --root <path>"; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown $1" >&2; exit 1 ;;
  esac
done
[[ -n "$ROOT" ]] || { usage; exit 1; }
f="$ROOT/project.yaml"
if [[ ! -f "$f" ]]; then
  echo "MISSING $f"
  exit 1
fi
req=(id name deploy ownership)
fail=0
for k in "${req[@]}"; do
  if ! grep -qE "^${k}:" "$f" && ! grep -qE "^  ${k}:" "$f" && ! grep -qE "^${k}:" "$f"; then
    # top-level keys only for id/name; deploy/ownership are blocks starting at column 0
    :
  fi
done
for k in id name; do
  grep -qE "^${k}:" "$f" || { echo "MISSING_KEY $k"; fail=1; }
done
for k in deploy ownership; do
  grep -qE "^${k}:" "$f" || { echo "MISSING_BLOCK $k"; fail=1; }
done
if [[ "$fail" -eq 0 ]]; then
  echo "OK $f"
  exit 0
fi
exit 1
