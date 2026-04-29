#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo /usr/local/bin/asdev-postgres-backup.sh && sudo ls -1dt /var/backups/asdev-postgres/* | head -n 1 | xargs -r sudo ls -lh"
