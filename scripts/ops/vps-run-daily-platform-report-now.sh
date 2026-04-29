#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo -n /usr/local/bin/asdev-daily-platform-report.sh && (test -f /var/log/asdev-daily-platform-report.log && tail -n 6 /var/log/asdev-daily-platform-report.log || true) && sed -n '1,180p' /var/log/asdev-monitoring/daily-platform-latest.md"
