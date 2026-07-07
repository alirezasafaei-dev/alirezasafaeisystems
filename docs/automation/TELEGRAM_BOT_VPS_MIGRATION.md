# Telegram Bot VPS Migration Plan

**Status:** Ready for execution
**Date:** 2026-07-07

## Mode 1: Long Polling (Recommended First)

**Why:**
- No public HTTPS needed
- No domain needed
- Works behind NAT
- Simple systemd restart on failure
- Good for early stage

**Setup:**

```bash
# On VPS
cd /opt/asdev/alirezasafaeisystems
# Configure bot token in .env
# Start bot with long polling
```

**Systemd unit:**

```ini
[Unit]
Description=ASDEV Telegram Bot
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/asdev/alirezasafaeisystems
ExecStart=/usr/bin/env bash -lc 'node scripts/telegram-bot.js'
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

## Mode 2: Webhook (Recommended Later)

**Requirements:**
- Public domain (e.g., bot.alirezasafaeisystems.ir)
- HTTPS certificate (Caddy auto-provisions)
- Reverse proxy (Caddy or Nginx)

**Architecture:**

```
Telegram → HTTPS → Caddy → localhost:3000 → Bot handler
```

**Caddyfile:**

```
bot.alirezasafaeisystems.ir {
    reverse_proxy localhost:3000
}
```

**Why later:**
- Needs domain setup
- Needs SSL
- More moving parts
- Long polling works fine for <1000 users

## Systemd Template

```ini
[Unit]
Description=ASDEV Telegram Bot (Webhook)
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/asdev/alirezasafaeisystems
ExecStart=/usr/bin/env bash -lc 'node scripts/telegram-bot.js --webhook'
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

## Do Not Implement Yet

Bot migration will happen only when:
1. VPS is running and stable
2. Owner requests Telegram bot activation
3. Bot code is ready for deployment
