#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Installing dependencies..."
npm install

echo "Creating .env from template..."
if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env — edit it with your real values"
else
  echo ".env already exists, skipping"
fi

echo ""
echo "Next steps:"
echo "1. Edit .env with your TELEGRAM_BOT_TOKEN and GITHUB_TOKEN"
echo "2. Run: node bot.js"
echo ""
echo "For systemd:"
echo "  sudo cp asdev-bot.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable asdev-bot"
echo "  sudo systemctl start asdev-bot"
