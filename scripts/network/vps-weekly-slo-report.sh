#!/usr/bin/env bash
set -euo pipefail

WATCH_LOG="${WATCH_LOG:-/var/log/asdev-health-watch.log}"
OUT_DIR="${OUT_DIR:-/var/log}"
LINES="${LINES:-12000}"
DATE_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
REPORT_FILE="$OUT_DIR/asdev-health-weekly-$(date -u +%Y%m%dT%H%M%SZ).md"
LATEST_LINK="$OUT_DIR/asdev-health-weekly-latest.md"

if [[ ! -f "$WATCH_LOG" ]]; then
  echo "watch log not found: $WATCH_LOG" >&2
  exit 1
fi

tail -n "$LINES" "$WATCH_LOG" > /tmp/asdev-health-weekly-tail.log

runs="$(grep -c 'health-watch done status=' /tmp/asdev-health-weekly-tail.log || true)"
ok_runs="$(grep -c 'health-watch done status=0' /tmp/asdev-health-weekly-tail.log || true)"
fail_runs="$(grep -c 'health-watch done status=1' /tmp/asdev-health-weekly-tail.log || true)"

if [[ "$runs" -eq 0 ]]; then
  availability="0.00"
else
  availability="$(awk -v ok="$ok_runs" -v total="$runs" 'BEGIN { printf "%.2f", (ok/total)*100 }')"
fi

{
  echo "# ASDEV Weekly Health Report"
  echo
  echo "- generated_at_utc: $DATE_UTC"
  echo "- source_log: $WATCH_LOG"
  echo "- sampled_lines: $LINES"
  echo "- total_runs: $runs"
  echo "- ok_runs: $ok_runs"
  echo "- fail_runs: $fail_runs"
  echo "- availability_percent: $availability"
  echo
  echo "## Endpoint Failure Counts"
  awk '
    /^(origin|edge)[[:space:]]+https?:\/\// {
      endpoint=$1" "$2;
      code=$4;
      if (code != "200") fail[endpoint]++;
      seen[endpoint]++;
    }
    END {
      if (length(seen)==0) {
        print "no endpoint lines found";
      } else {
        for (k in seen) {
          f=(k in fail)?fail[k]:0;
          printf("- %s => failures: %d\n", k, f);
        }
      }
    }
  ' /tmp/asdev-health-weekly-tail.log
  echo
  echo "## Recent Status Samples"
  grep 'health-watch done status=' /tmp/asdev-health-weekly-tail.log | tail -n 20 || true
} > "$REPORT_FILE"

ln -sfn "$REPORT_FILE" "$LATEST_LINK"

if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  summary="ASDEV Weekly SLO\navailability: ${availability}%\nruns: ${runs}\nfail_runs: ${fail_runs}\nreport: ${REPORT_FILE}"
  curl -sS --max-time 10 \
    -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${summary}" \
    >/dev/null || true
fi

echo "WEEKLY_REPORT=${REPORT_FILE}"
