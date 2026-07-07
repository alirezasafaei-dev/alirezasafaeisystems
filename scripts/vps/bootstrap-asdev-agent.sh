#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "[BOOTSTRAP] $*"; }
ok() { echo -e "[OK] $*"; }
fail() { echo -e "[FAIL] $*"; }

if [ "$(id -u)" -ne 0 ]; then
  fail "This script must be run as root (sudo)"
  exit 1
fi

ASDEV_USER="asdev"
ASDEV_HOME="/home/${ASDEV_USER}"
ASDEV_DIR="/opt/asdev"
LOG_DIR="/var/log/asdev-agent"

log "=== ASDEV VPS Bootstrap ==="

log "Creating asdev user..."
if ! id "$ASDEV_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$ASDEV_USER"
  ok "User created"
else
  ok "User exists"
fi

log "Installing base packages..."
apt-get update -qq
apt-get install -y -qq \
  git curl jq ufw fail2ban unzip build-essential \
  ca-certificates gnupg lsb-release systemd \
  rsync htop tmux

ok "Base packages installed"

log "Installing Node.js LTS..."
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt-get install -y -qq nodejs
fi
ok "Node.js: $(node --version)"

log "Enabling corepack..."
corepack enable
corepack prepare pnpm@latest --activate
ok "pnpm: $(pnpm --version)"

log "Installing GitHub CLI..."
if ! command -v gh >/dev/null 2>&1; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  apt-get update -qq
  apt-get install -y -qq gh
fi
ok "gh: $(gh --version | head -1)"

log "Creating directories..."
mkdir -p "$ASDEV_DIR" "$LOG_DIR"
chown -R "$ASDEV_USER:$ASDEV_USER" "$ASDEV_DIR" "$LOG_DIR"
ok "Directories created"

log "Configuring UFW..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable
ok "UFW configured"

log "Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban
ok "fail2ban active"

log "=== Bootstrap Complete ==="
echo ""
echo "Next steps for ${ASDEV_USER}:"
echo "  1. su - ${ASDEV_USER}"
echo "  2. gh auth login"
echo "  3. bash scripts/vps/sync-repos-to-vps.sh"
echo "  4. cp ops/systemd/vps/*.service ~/.config/systemd/user/"
echo "  5. cp ops/systemd/vps/*.timer ~/.config/systemd/user/"
echo "  6. systemctl --user daemon-reload"
echo "  7. systemctl --user enable --now asdev-agent-loop.timer"
echo "  8. loginctl enable-linger ${ASDEV_USER}"
