#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" <<'REMOTE'
set -euo pipefail

echo "=== readiness ==="
for url in \
  "https://alirezasafaeisystems.ir/api/ready" \
  "https://persiantoolbox.ir/api/ready" \
  "https://audit.alirezasafaeisystems.ir/api/ready"
do
  code="$(curl -sS -o /dev/null -w '%{http_code}' "$url" || true)"
  echo "$url => $code"
done

echo
echo "=== redis watch latest ==="
if [[ -f /var/log/asdev-monitoring/redis-watch-latest.json ]]; then
  sudo cat /var/log/asdev-monitoring/redis-watch-latest.json
else
  echo "missing /var/log/asdev-monitoring/redis-watch-latest.json"
fi

echo
echo "=== edge probe tail ==="
if [[ -f /var/log/asdev-arvan-edge-probe.log ]]; then
  sudo tail -n 20 /var/log/asdev-arvan-edge-probe.log
else
  echo "missing /var/log/asdev-arvan-edge-probe.log"
fi

echo
echo "=== daily report latest ==="
if [[ -f /var/log/asdev-monitoring/daily-platform-latest.md ]]; then
  latest="$(readlink -f /var/log/asdev-monitoring/daily-platform-latest.md || true)"
  echo "${latest:-/var/log/asdev-monitoring/daily-platform-latest.md}"
  sudo tail -n 30 /var/log/asdev-monitoring/daily-platform-latest.md
elif ls /var/log/asdev-monitoring/daily-platform-*.md >/dev/null 2>&1; then
  latest="$(ls -1 /var/log/asdev-monitoring/daily-platform-*.md | tail -n1)"
  echo "$latest"
  sudo tail -n 30 "$latest"
else
  echo "no daily markdown reports yet"
fi

echo
echo "=== pm2 status ==="
pm2 jlist | jq -r '.[] | "\(.name)\tstatus=\(.pm2_env.status)\trestarts=\(.pm2_env.restart_time)"' || true
REMOTE
