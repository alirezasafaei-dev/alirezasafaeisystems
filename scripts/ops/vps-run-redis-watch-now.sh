#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo -n /usr/local/bin/asdev-redis-watch.sh && sudo -n tail -n 8 /var/log/asdev-redis-watch.log && sudo -n sed -n '1,140p' /var/log/asdev-monitoring/redis-watch-latest.json"
