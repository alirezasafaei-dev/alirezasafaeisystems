#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" \
  "sudo /usr/local/bin/asdev-arvan-edge-probe.sh; sudo tail -n 40 /var/log/asdev-arvan-edge-probe.log"
