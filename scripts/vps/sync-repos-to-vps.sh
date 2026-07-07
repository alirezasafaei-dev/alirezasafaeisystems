#!/usr/bin/env bash
set -euo pipefail

VPS_TARGET="${1:-user@server-ip}"
REPOS_DIR="/home/asdev/repos"

log() { echo -e "[SYNC] $*"; }
ok() { echo -e "[OK] $*"; }

if [ "$VPS_TARGET" = "user@server-ip" ]; then
  echo "Usage: bash scripts/vps/sync-repos-to-vps.sh user@server-ip"
  echo "Replace with your actual VPS address."
  exit 1
fi

log "Syncing to ${VPS_TARGET}"

log "Creating target directories..."
ssh "$VPS_TARGET" "mkdir -p ${REPOS_DIR}/alirezasafaeisystems ${REPOS_DIR}/auditsystems"

log "Syncing alirezasafaeisystems..."
rsync -avz --delete \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude '.state/' \
  --exclude 'node_modules/' \
  --exclude '.next/' \
  --exclude '.git/' \
  --exclude 'ops/automation-logs/' \
  ./ "$VPS_TARGET:${REPOS_DIR}/alirezasafaeisystems/"

log "Syncing auditsystems..."
rsync -avz --delete \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude '.state/' \
  --exclude 'node_modules/' \
  --exclude '.next/' \
  --exclude '.git/' \
  --exclude 'ops/automation-logs/' \
  --exclude 'test-results/' \
  ../sites/live/auditsystems/ "$VPS_TARGET:${REPOS_DIR}/auditsystems/"

log "Installing dependencies on VPS..."
ssh "$VPS_TARGET" "export PATH=\$HOME/node/bin:\$PATH && cd ${REPOS_DIR}/auditsystems && NODE_OPTIONS='--max-old-space-size=2048' pnpm install --frozen-lockfile 2>/dev/null || NODE_OPTIONS='--max-old-space-size=2048' pnpm install"

log "=== Sync Complete ==="
echo ""
echo "Next steps on VPS:"
echo "  1. cd ${REPOS_DIR}/alirezasafaeisystems"
echo "  2. export PATH=\$HOME/node/bin:\$PATH"
echo "  3. gh auth login"
echo "  4. cp ops/systemd/vps/*.service ~/.config/systemd/user/"
echo "  5. cp ops/systemd/vps/*.timer ~/.config/systemd/user/"
echo "  6. systemctl --user daemon-reload"
echo "  7. systemctl --user enable --now asdev-agent-loop.timer"
