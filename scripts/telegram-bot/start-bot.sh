#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/asdev
export PATH=/home/asdev/node/bin:/usr/local/bin:/usr/bin:/bin
cd /home/asdev/repos/alirezasafaeisystems/scripts/telegram-bot
export $(grep -v '^#' .env | xargs)
exec /home/asdev/node/bin/node bot.js
