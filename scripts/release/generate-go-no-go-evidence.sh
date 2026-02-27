#!/usr/bin/env bash
set -euo pipefail

SITE_URL="${SITE_URL:-}"
STAGING_URL="${STAGING_URL:-}"
OUT_DIR="${OUT_DIR:-docs/runtime/GoNoGo_Evidence}"
RUN_VERIFY="${RUN_VERIFY:-1}"
RUN_SMOKE="${RUN_SMOKE:-1}"
RUN_LIGHTHOUSE="${RUN_LIGHTHOUSE:-0}"
VALIDATE_OWNERSHIP="${VALIDATE_OWNERSHIP:-1}"
OWNERSHIP_DOC="${OWNERSHIP_DOC:-docs/ONCALL_ESCALATION.md}"

if [[ -z "$SITE_URL" ]]; then
  echo "SITE_URL is required. Example: SITE_URL=https://alirezasafaeisystems.ir $0" >&2
  exit 1
fi

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUT_DIR" artifacts

BASENAME="go-no-go-${TIMESTAMP}"
REPORT_FILE="$OUT_DIR/${BASENAME}.md"
SUMMARY_FILE="artifacts/${BASENAME}.summary.txt"

VERIFY_STATUS="skipped"
SMOKE_STATUS="skipped"
LHCI_STATUS="skipped"
OWNERSHIP_STATUS="skipped"
CURL_NO_PROXY="${CURL_NO_PROXY:-*}"

run_and_capture() {
  local label="$1"
  local command="$2"
  local logfile="$3"
  set +e
  bash -lc "$command" >"$logfile" 2>&1
  local exit_code=$?
  set -e
  echo "$label exit=$exit_code log=$logfile" >> "$SUMMARY_FILE"
  return "$exit_code"
}

: > "$SUMMARY_FILE"

if [[ "$RUN_VERIFY" == "1" ]]; then
  if run_and_capture "verify" "pnpm -s run verify" "artifacts/${BASENAME}.verify.log"; then
    VERIFY_STATUS="pass"
  else
    VERIFY_STATUS="fail"
  fi
fi

if [[ "$RUN_SMOKE" == "1" ]]; then
  if run_and_capture "smoke" "PORT=3100 pnpm run start >/tmp/alirezasafaeisystems-smoke-server.log 2>&1 & srv=\$!; for i in {1..40}; do code=\$(curl -s -o /dev/null -w \"%{http_code}\" http://127.0.0.1:3100/ || true); if [[ \"\$code\" != \"000\" ]]; then break; fi; sleep 1; done; PLAYWRIGHT_DISABLE_WEBSERVER=true PLAYWRIGHT_BASE_URL=http://127.0.0.1:3100 pnpm -s run test:e2e:smoke; ec=\$?; kill \$srv >/dev/null 2>&1 || true; wait \$srv 2>/dev/null || true; exit \$ec" "artifacts/${BASENAME}.smoke.log"; then
    SMOKE_STATUS="pass"
  else
    SMOKE_STATUS="fail"
  fi
fi

if [[ "$RUN_LIGHTHOUSE" == "1" ]]; then
  if run_and_capture "lighthouse" "pnpm -s run lighthouse:ci" "artifacts/${BASENAME}.lighthouse.log"; then
    LHCI_STATUS="pass"
  else
    LHCI_STATUS="fail"
  fi
fi

if [[ "$VALIDATE_OWNERSHIP" == "1" ]]; then
  if run_and_capture "ownership" "bash scripts/release/validate-ownership.sh \"${OWNERSHIP_DOC}\"" "artifacts/${BASENAME}.ownership.log"; then
    OWNERSHIP_STATUS="pass"
  else
    OWNERSHIP_STATUS="fail"
  fi
fi

safe_http_code() {
  local url="$1"
  local code
  code="$(curl --noproxy "${CURL_NO_PROXY}" -s --connect-timeout 5 --max-time 15 -o /dev/null -w "%{http_code}" "${url}" || true)"
  if [[ -z "$code" || "$code" == "000" ]]; then
    echo "unreachable"
  else
    echo "$code"
  fi
}

safe_header() {
  local url="$1"
  local header_name="$2"
  local headers
  headers="$(curl --noproxy "${CURL_NO_PROXY}" -sI --connect-timeout 5 --max-time 15 "${url}" || true)"
  if [[ -z "$headers" ]]; then
    echo "missing"
    return
  fi
  local value
  value="$(printf '%s' "$headers" | awk -v h="$header_name" 'BEGIN{IGNORECASE=1} $0 ~ "^" h ":" {sub(/\r$/,""); print; exit}')"
  if [[ -z "$value" ]]; then
    echo "missing"
  else
    echo "$value"
  fi
}

live_code="$(safe_http_code "${SITE_URL%/}/")"
ready_code="$(safe_http_code "${SITE_URL%/}/api/ready")"
hsts_value="$(safe_header "${SITE_URL%/}/" "strict-transport-security")"

staging_code="n/a"
if [[ -n "$STAGING_URL" ]]; then
  staging_code="$(safe_http_code "${STAGING_URL%/}/api/ready")"
fi

extract_value() {
  local key="$1"
  if [[ ! -f "$OWNERSHIP_DOC" ]]; then
    echo "not-set"
    return
  fi
  local line
  line="$(awk -F': ' -v k="$key" '$0 ~ "^- " k ":" {print $2; exit}' "$OWNERSHIP_DOC")"
  if [[ -z "$line" ]]; then
    echo "not-set"
  else
    printf '%s\n' "$line" | sed -E 's/^`//; s/`$//'
  fi
}

release_approver="$(extract_value "Release approver")"
oncall_primary="$(extract_value "Primary on-call")"
oncall_backup="$(extract_value "Backup on-call")"
incident_commander="$(extract_value "Incident commander \\(P1/P0\\)")"

LATEST_INCIDENT="$(ls -1t docs/runtime/Incidents/*_rollback-drill-*.md 2>/dev/null | head -n 1 || true)"
if [[ -z "$LATEST_INCIDENT" ]]; then
  LATEST_INCIDENT="not-found"
fi

cat > "$REPORT_FILE" <<REPORT
# Go/No-Go Evidence Bundle

- Timestamp (UTC): ${TIMESTAMP}
- Commit: $(git rev-parse --short HEAD)
- Branch: $(git rev-parse --abbrev-ref HEAD)
- Site URL: ${SITE_URL}
- Staging URL: ${STAGING_URL:-not-set}

## Quality Gates
- verify: ${VERIFY_STATUS}
- e2e smoke: ${SMOKE_STATUS}
- lighthouse: ${LHCI_STATUS}
- ownership: ${OWNERSHIP_STATUS}

## Live Health Evidence
- GET ${SITE_URL%/}/ -> ${live_code}
- GET ${SITE_URL%/}/api/ready -> ${ready_code}
- HSTS header: ${hsts_value:-missing}
- GET ${STAGING_URL:-n/a}/api/ready -> ${staging_code}
- Latest rollback incident note: ${LATEST_INCIDENT}

## Ownership Checklist
- Release approver: \`${release_approver}\`
- On-call primary: \`${oncall_primary}\`
- On-call backup: \`${oncall_backup}\`
- Incident commander: \`${incident_commander}\`

## Artifacts
- summary: \`${SUMMARY_FILE}\`
- verify log: \`artifacts/${BASENAME}.verify.log\`
- smoke log: \`artifacts/${BASENAME}.smoke.log\`
- lighthouse log: \`artifacts/${BASENAME}.lighthouse.log\`
- ownership log: \`artifacts/${BASENAME}.ownership.log\`

## Decision
$(if [[ "$VERIFY_STATUS" == "pass" && "$SMOKE_STATUS" == "pass" && "$OWNERSHIP_STATUS" != "fail" && "$ready_code" == "200" ]]; then
    echo "- Suggested decision: **GO** (pending human ownership sign-off)."
  else
    echo "- Suggested decision: **NO-GO** until failed gates are resolved."
  fi)
REPORT

echo "report=${REPORT_FILE}"
echo "summary=${SUMMARY_FILE}"
