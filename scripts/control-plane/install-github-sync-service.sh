#!/usr/bin/env bash
# Install ASDEV GitHub sync as a user systemd timer.
set -Eeuo pipefail

REPO_DIR="${ASDEV_REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${SYSTEMD_USER_DIR}/asdev-github-sync.service"
TIMER_FILE="${SYSTEMD_USER_DIR}/asdev-github-sync.timer"
ENVIRONMENT_NAME="${ASDEV_ENVIRONMENT:-AUTOMATION_SERVER}"

mkdir -p "$SYSTEMD_USER_DIR"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "ERROR: not a git repository: $REPO_DIR" >&2
  exit 1
fi

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=ASDEV GitHub/local/server sync
Documentation=$REPO_DIR/docs/ops/GITHUB_LOCAL_SERVER_SYNC.md
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
WorkingDirectory=$REPO_DIR
Environment=ASDEV_ENVIRONMENT=$ENVIRONMENT_NAME
Environment=ASDEV_REPO_DIR=$REPO_DIR
ExecStart=/usr/bin/env bash $REPO_DIR/scripts/control-plane/sync-github-local-server.sh
TimeoutStartSec=180
EOF

cat > "$TIMER_FILE" <<'EOF'
[Unit]
Description=Run ASDEV GitHub/local/server sync every 5 minutes

[Timer]
OnBootSec=90s
OnUnitActiveSec=5min
Persistent=true
RandomizedDelaySec=30s
Unit=asdev-github-sync.service

[Install]
WantedBy=timers.target
EOF

chmod 0644 "$SERVICE_FILE" "$TIMER_FILE"
chmod +x "$REPO_DIR/scripts/control-plane/sync-github-local-server.sh" 2>/dev/null || true

systemctl --user daemon-reload
systemctl --user enable --now asdev-github-sync.timer

if command -v loginctl >/dev/null 2>&1; then
  loginctl enable-linger "$(id -un)" 2>/dev/null || true
fi

systemctl --user status asdev-github-sync.timer --no-pager
systemctl --user list-timers --all | grep -E 'asdev-github-sync|NEXT' || true

echo "Installed ASDEV GitHub sync timer for $ENVIRONMENT_NAME at $REPO_DIR"
