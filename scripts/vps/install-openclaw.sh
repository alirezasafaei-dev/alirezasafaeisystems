#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_USER="openclaw"
OPENCLAW_HOME="/home/${OPENCLAW_USER}"

log() { echo -e "[OPENCLAW-INSTALL] $*"; }
ok() { echo -e "[OK] $*"; }

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (sudo)"
  exit 1
fi

log "=== OpenClaw Phase 1 Installation ==="

log "Creating openclaw user..."
if ! id "$OPENCLAW_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$OPENCLAW_USER"
  ok "User created"
else
  ok "User exists"
fi

log "Installing Node.js 22 LTS for openclaw user..."
su - "$OPENCLAW_USER" -c '
  curl -fsSL https://nodejs.org/dist/v22.16.0/node-v22.16.0-linux-x64.tar.xz -o /tmp/node.tar.xz
  mkdir -p ~/node
  tar -xJf /tmp/node.tar.xz -C ~/node --strip-components=1
  rm /tmp/node.tar.xz
  echo "export PATH=\$HOME/node/bin:\$PATH" >> ~/.bashrc
  ~/node/bin/node -v
'
ok "Node.js installed"

log "Installing OpenClaw..."
su - "$OPENCLAW_USER" -c '
  export PATH=$HOME/node/bin:$PATH
  npm install -g openclaw@latest 2>&1 | tail -3
  openclaw --version 2>/dev/null || echo "openclaw installed"
'
ok "OpenClaw installed"

log "Creating workspace directories..."
su - "$OPENCLAW_USER" -c '
  mkdir -p ~/.openclaw/workspace/skills/asdev-status
  mkdir -p ~/.openclaw/workspace/skills/asdev-commands
'
ok "Directories created"

log "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "  1. su - openclaw"
echo "  2. Create ~/.openclaw/openclaw.json with config"
echo "  3. Add Telegram bot token"
echo "  4. Add GitHub read-only token"
echo "  5. Add OpenAI API key"
echo "  6. openclaw onboard --install-daemon"
echo "  7. Test: openclaw gateway status"
