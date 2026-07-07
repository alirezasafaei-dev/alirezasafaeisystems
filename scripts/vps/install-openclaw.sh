#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_USER="openclaw"
OPENCLAW_HOME="/home/${OPENCLAW_USER}"
OPENCLAW_VERSION="${OPENCLAW_VERSION:-latest}"
NODE_VERSION="v24.0.0"

log() { echo -e "[OPENCLAW-INSTALL] $*"; }
ok() { echo -e "[OK] $*"; }
fail() { echo -e "[FAIL] $*"; }

if [ "$(id -u)" -ne 0 ]; then
  fail "This script must be run as root (sudo)"
  exit 1
fi

log "=== OpenClaw Phase 1 Installation (No-LLM Mode) ==="
log "Version: ${OPENCLAW_VERSION}"
log "Node: ${NODE_VERSION}"
log "LLM Provider: UNCONFIGURED (no paid API approved)"
echo ""

log "Creating openclaw user..."
if ! id "$OPENCLAW_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$OPENCLAW_USER"
  ok "User created"
else
  ok "User exists"
fi

log "Installing Node.js ${NODE_VERSION} for openclaw user..."
su - "$OPENCLAW_USER" -c "
  curl -fsSL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz -o /tmp/node.tar.xz
  mkdir -p ~/node
  tar -xJf /tmp/node.tar.xz -C ~/node --strip-components=1
  rm /tmp/node.tar.xz
  echo 'export PATH=\$HOME/node/bin:\$PATH' >> ~/.bashrc
  ~/node/bin/node -v
"
ok "Node.js installed"

log "Installing OpenClaw ${OPENCLAW_VERSION}..."
su - "$OPENCLAW_USER" -c "
  export PATH=\$HOME/node/bin:\$PATH
  npm install -g openclaw@${OPENCLAW_VERSION} 2>&1 | tail -3
  INSTALLED_VERSION=\$(openclaw --version 2>/dev/null || echo 'unknown')
  echo \"Installed: \${INSTALLED_VERSION}\"
"
ok "OpenClaw installed"

log "Creating workspace directories..."
su - "$OPENCLAW_USER" -c "
  mkdir -p ~/.openclaw/workspace/skills/asdev-status
"
ok "Directories created"

log "=== Post-Install Checks ==="
su - "$OPENCLAW_USER" -c "
  export PATH=\$HOME/node/bin:\$PATH
  echo '--- Version ---'
  openclaw --version 2>/dev/null || echo 'openclaw version check failed'
  echo '--- Node ---'
  node -v
  echo '--- npm ---'
  npm -v
"

log "=== Installation Complete ==="
echo ""
echo "Phase 1: No-LLM Telegram Status Bot"
echo "  - Reads Issue #45 and PRs via GitHub API"
echo "  - Returns structured status to Telegram"
echo "  - No LLM required"
echo "  - No paid API key needed"
echo ""
echo "Next steps:"
echo "  1. su - openclaw"
echo "  2. Create ~/.openclaw/openclaw.json (see openclaw.json.example)"
echo "  3. Add secrets: Telegram bot token, GitHub fine-grained token"
echo "  4. openclaw onboard --install-daemon"
echo "  5. Run: bash scripts/vps/verify-openclaw-phase1.sh"
echo ""
echo "Phase 1 scope: READ-ONLY status bot only"
echo "Phase 1 does NOT: submit commands, create PRs, deploy, edit PersianToolbox"
echo "Phase 1 does NOT: require OpenAI API or any paid LLM provider"
