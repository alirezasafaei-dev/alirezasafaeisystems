#!/usr/bin/env bash
set -euo pipefail

MAX_ATTEMPTS=10
INITIAL_DELAY=5
DELAY=$INITIAL_DELAY
MAX_DELAY=60

log() { echo -e "[NETWORK] $*"; }

check_dns() {
  getent hosts github.com >/dev/null 2>&1
}

check_github_api() {
  curl -fsS --max-time 10 https://api.github.com/rate_limit >/dev/null 2>&1
}

check_gh_auth() {
  gh auth status >/dev/null 2>&1
}

for attempt in $(seq 1 $MAX_ATTEMPTS); do
  log "Attempt ${attempt}/${MAX_ATTEMPTS}"

  if check_dns && check_github_api && check_gh_auth; then
    log "Network OK"
    exit 0
  fi

  if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
    log "Network unavailable, retrying in ${DELAY}s"
    sleep "$DELAY"
    DELAY=$((DELAY * 2))
    [ "$DELAY" -gt "$MAX_DELAY" ] && DELAY=$MAX_DELAY
  fi
done

log "Network unavailable after ${MAX_ATTEMPTS} attempts"
exit 1
