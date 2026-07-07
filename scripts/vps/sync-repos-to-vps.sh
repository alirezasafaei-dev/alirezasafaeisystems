#!/usr/bin/env bash
set -euo pipefail

VPS_TARGET="${1:-user@server-ip}"
ASDEV_DIR="/opt/asdev"

log() { echo -e "[SYNC] $*"; }
ok() { echo -e "[OK] $*"; }

if [ "$VPS_TARGET" = "user@server-ip" ]; then
  echo "Usage: bash scripts/vps/sync-repos-to-vps.sh user@server-ip"
  echo "Replace with your actual VPS address."
  exit 1
fi

log "Syncing to ${VPS_TARGET}"

log "Creating target directories..."
ssh "$VPS_TARGET" "mkdir -p ${ASDEV_DIR}/alirezasafaeisystems ${ASDEV_DIR}/auditsystems ${ASDEV_DIR}/persiantoolbox"

log "Syncing alirezasafaeisystems..."
rsync -avz --delete \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude '.state/' \
  --exclude 'node_modules/' \
  --exclude '.next/' \
  --exclude '.git/' \
  --exclude 'ops/automation-logs/' \
  ./ "$VPS_TARGET:${ASDEV_DIR}/alirezasafaeisystems/"

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
  ../sites/live/auditsystems/ "$VPS_TARGET:${ASDEV_DIR}/auditsystems/"

log "Installing dependencies on VPS..."
ssh "$VPS_TARGET" "cd ${ASDEV_DIR}/auditsystems && pnpm install --frozen-lockfile 2>/dev/null || pnpm install"

log "Running validation..."
ssh "$VPS_TARGET" "cd ${ASDEV_DIR}/auditsystems && pnpm typecheck 2>&1 | tail -1 && pnpm lint 2>&1 | tail -1"

log "=== Sync Complete ==="
echo ""
echo "Next steps on VPS:"
echo "  1. gh auth login"
echo "  2. cp ${ASDEV_DIR}/alirezasafaeisystems/ops/systemd/vps/*.service ~/.config/systemd/user/"
echo "  3. cp ${ASDEV_DIR}/alirezasafaeisystems/ops/systemd/vps/*.timer ~/.config/systemd/user/"
echo "  4. systemctl --user daemon-reload"
echo "  5. systemctl --user enable --now asdev-agent-loop.timer"
echo "  6. loginctl enable-linger asdev"
