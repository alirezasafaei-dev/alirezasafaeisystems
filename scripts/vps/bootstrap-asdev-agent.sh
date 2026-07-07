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

log "=== ASDEV VPS Bootstrap ==="

log "Creating asdev user..."
if ! id "$ASDEV_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$ASDEV_USER"
  ok "User created"
else
  ok "User exists"
fi

log "Setting passwordless sudo..."
echo "${ASDEV_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${ASDEV_USER}"
chmod 440 "/etc/sudoers.d/${ASDEV_USER}"
ok "Passwordless sudo configured"

log "Installing base packages..."
apt-get update -qq
apt-get install -y -qq \
  git curl jq ufw fail2ban unzip build-essential \
  ca-certificates gnupg lsb-release systemd \
  rsync htop tmux software-properties-common apt-transport-https

ok "Base packages installed"

log "Installing Node.js LTS to user directory..."
su - "$ASDEV_USER" -c '
  curl -fsSL https://nodejs.org/dist/v22.16.0/node-v22.16.0-linux-x64.tar.xz -o /tmp/node.tar.xz
  mkdir -p ~/node
  tar -xJf /tmp/node.tar.xz -C ~/node --strip-components=1
  rm /tmp/node.tar.xz
  echo "export PATH=\$HOME/node/bin:\$PATH" >> ~/.bashrc
  ~/node/bin/node -v
  ~/node/bin/npm install -g pnpm 2>/dev/null
  ~/node/bin/pnpm -v
'
ok "Node.js installed"

log "Installing GitHub CLI..."
su - "$ASDEV_USER" -c '
  GH_VERSION=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep tag_name | cut -d"\"" -f4 | sed "s/v//")
  curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" -o /tmp/gh.tar.gz
  tar -xzf /tmp/gh.tar.gz -C /tmp
  cp /tmp/gh_${GH_VERSION}_linux_amd64/bin/gh ~/node/bin/
  rm -rf /tmp/gh*
  ~/node/bin/gh --version | head -1
'
ok "gh CLI installed"

log "Creating directories..."
su - "$ASDEV_USER" -c '
  mkdir -p ~/repos ~/repos/log ~/.config/systemd/user
'
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

log "Enabling linger..."
loginctl enable-linger "$ASDEV_USER"
ok "Linger enabled"

log "=== Bootstrap Complete ==="
echo ""
echo "Next steps for ${ASDEV_USER}:"
echo "  1. su - ${ASDEV_USER}"
echo "  2. export PATH=\$HOME/node/bin:\$PATH"
echo "  3. gh auth login"
echo "  4. cd ~/repos && git clone git@github.com:alirezasafaei-dev/alirezasafaeisystems.git"
echo "  5. cd ~/repos && git clone git@github.com:alirezasafaei-dev/auditsystems.git"
echo "  6. cd ~/repos/alirezasafaeisystems && pnpm install"
echo "  7. cd ~/repos/auditsystems && NODE_OPTIONS='--max-old-space-size=2048' pnpm install"
echo "  8. cp ~/repos/alirezasafaeisystems/ops/systemd/vps/*.service ~/.config/systemd/user/"
echo "  9. cp ~/repos/alirezasafaeisystems/ops/systemd/vps/*.timer ~/.config/systemd/user/"
echo " 10. systemctl --user daemon-reload"
echo " 11. systemctl --user enable --now asdev-agent-loop.timer"
