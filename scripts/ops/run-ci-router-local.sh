#!/usr/bin/env bash
# Local equivalent of .github/workflows/ci-router.yml safe-checks.
# Use when GitHub Actions infrastructure is degraded.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

BASE_REF="${1:-origin/main}"
ERRORS=0

log() { echo "[ci-router-local] $*"; }
fail() { echo "[ci-router-local] ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }

log "Project: $PROJECT_ROOT"
log "Base:    $BASE_REF"

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  log "Base ref missing locally; fetching..."
  git fetch origin main:refs/remotes/origin/main 2>/dev/null || true
fi

CHANGED=$(git diff --name-only "${BASE_REF}...HEAD" 2>/dev/null || git diff --name-only HEAD~1)
printf '%s\n' "$CHANGED" > /tmp/asdev_changed_files.txt
log "Changed files:"
sed 's/^/  /' /tmp/asdev_changed_files.txt || true

log "Syntax-check changed shell scripts..."
scripts=$(grep -E '\.sh$' /tmp/asdev_changed_files.txt || true)
if [[ -n "$scripts" ]]; then
  while IFS= read -r f; do
    [[ -z "$f" || ! -f "$f" ]] && continue
    log "  bash -n $f"
    bash -n "$f" || fail "bash -n failed: $f"
  done <<<"$scripts"
else
  log "  No changed shell scripts."
fi

log "Registry schema (if deploy/ops touched)..."
if grep -qx 'deploy/registry.tsv' /tmp/asdev_changed_files.txt || grep -qE '^scripts/(deploy|ops)/' /tmp/asdev_changed_files.txt || grep -qE '^deploy/' /tmp/asdev_changed_files.txt; then
  bash ./scripts/ops/validate-registry-schema.sh || fail "registry validation failed"
else
  log "  skip"
fi

log "Dangerous patterns (if deploy/ops touched)..."
if grep -qE '^scripts/(deploy|ops)/' /tmp/asdev_changed_files.txt; then
  bash ./scripts/ops/check-dangerous-patterns.sh --project-root . || fail "dangerous pattern check failed"
else
  log "  skip"
fi

log "Sensitive path scan..."
BLOCK_PATTERNS='(^|/)\.env$|(^|/)\.env\.[^.]+$|credentials|(^|/).*\.pem$|(^|/).*\.key$|id_rsa|(^|/).*\.p12$'
ALLOW_PATTERNS='\.example\.env$|\.env\.example$|example|template|docs/'
violations=0
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if echo "$path" | grep -qiE "$BLOCK_PATTERNS"; then
    if echo "$path" | grep -qiE "$ALLOW_PATTERNS"; then
      log "  allowed: $path"
    else
      fail "Sensitive-looking path: $path"
      violations=$((violations + 1))
    fi
  fi
done < /tmp/asdev_changed_files.txt
[[ $violations -eq 0 ]] && log "  No disallowed sensitive files."

echo "========================================"
if [[ $ERRORS -gt 0 ]]; then
  echo "CI ROUTER LOCAL: FAILED ($ERRORS)"
  exit 1
fi
echo "CI ROUTER LOCAL: PASSED"
exit 0
