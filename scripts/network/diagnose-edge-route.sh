#!/usr/bin/env bash
set -euo pipefail

DOMAINS=(
  "persiantoolbox.ir"
  "alirezasafaeisystems.ir"
  "audit.alirezasafaeisystems.ir"
)

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
ACCESS_LOG="${ACCESS_LOG:-/var/log/nginx/access.log}"
OUT_DIR="${OUT_DIR:-/home/dev/Project_Me_All/Project_Me/alirezasafaeisystems/reports/edge-route}"

mkdir -p "$OUT_DIR"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT="$OUT_DIR/${RUN_ID}-edge-route.md"

{
  echo "# Edge Route Diagnosis (${RUN_ID})"
  echo
  echo "- Host: $(hostname)"
  echo "- SSH target: ${SSH_HOST}"
  echo
  echo "| Domain | Default Status | NoProxy Status | Origin hit (NoProxy path) | Origin hit (Proxy path) | Verdict |"
  echo "|---|---:|---:|---|---|---|"

  for domain in "${DOMAINS[@]}"; do
    diag_path="/diag-edge-$(date +%s)-$RANDOM"

    default_status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 25 "https://${domain}${diag_path}" || echo ERR)"
    noproxy_status="$(curl -sS -o /dev/null -w '%{http_code}' --noproxy '*' --max-time 25 "https://${domain}${diag_path}" || echo ERR)"

    # grep exact path from origin log
    remote_hits="$(ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo grep -F '${diag_path}' '${ACCESS_LOG}' | tail -n 5" || true)"

    noproxy_hit="no"
    proxy_hit="no"

    if echo "$remote_hits" | grep -q "$diag_path"; then
      # We sent noproxy after default; at least one hit means origin reachable via noproxy path.
      noproxy_hit="yes"
      # If default is 2xx/3xx/4xx but not 504 and remote has >=2 lines, likely both reached.
      hit_count="$(echo "$remote_hits" | sed '/^$/d' | wc -l | tr -d ' ')"
      if [[ "$default_status" != "504" && "$default_status" != "ERR" && "$hit_count" -ge 2 ]]; then
        proxy_hit="likely"
      fi
    fi

    verdict="ok"
    if [[ "$default_status" == "504" && "$noproxy_status" != "504" ]]; then
      verdict="edge-route-failure-before-origin"
    elif [[ "$default_status" == "504" && "$noproxy_status" == "504" ]]; then
      verdict="global-origin-or-edge-failure"
    fi

    echo "| ${domain} | ${default_status} | ${noproxy_status} | ${noproxy_hit} | ${proxy_hit} | ${verdict} |"
  done

  echo
  echo "## Interpretation"
  echo "- If Default=504 but NoProxy!=504 and origin hit exists, issue is on CDN/proxy route before origin."
  echo "- If both are 504, inspect origin app/nginx availability."
  echo
  echo "## Next Actions"
  echo "1. In CDN panel, check origin protocol/port and connectivity from all POPs."
  echo "2. Keep a direct non-CDN fallback host for emergency access."
  echo "3. Submit report with run id: ${RUN_ID} to CDN support."
} > "$REPORT"

echo "REPORT=${REPORT}"
