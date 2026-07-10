#!/usr/bin/env bash
# Install ASDEV Supervisor systemd user service and timer
set -Euo pipefail

SERVICE_NAME="asdev-supervisor"
ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
UNIT_DIR="${ASDEV_UNIT_DIR:-$HOME/.config/systemd/user}"

mkdir -p "$UNIT_DIR"

# Service file
cat > "$UNIT_DIR/$SERVICE_NAME.service" <<UNIT
[Unit]
Description=ASDEV Self-Healing Supervisor — pre-loop health gate
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$ASDEV_ROOT/scripts/control-plane/asdev-supervisor.sh
Environment=ASDEV_ENVIRONMENT=%H
Environment=ASDEV_ROOT=$ASDEV_ROOT
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
UNIT

# Timer — runs every 5 minutes, before the agent loop
cat > "$UNIT_DIR/$SERVICE_NAME.timer" <<UNIT
[Unit]
Description=ASDEV Supervisor Timer — pre-loop health check

[Timer]
OnCalendar=*:0/5
Persistent=false
RandomizedDelaySec=10

[Install]
WantedBy=default.target
UNIT

systemctl --user daemon-reload
systemctl --user enable "$SERVICE_NAME.timer"
systemctl --user start "$SERVICE_NAME.timer"

echo "=== $SERVICE_NAME installed ==="
systemctl --user status "$SERVICE_NAME.timer" --no-pager
