# ASDEV Telegram Status Bot

No-LLM Telegram bot that reads GitHub API data and returns structured status.

## Prerequisites

- Node.js >= 18
- `gh` CLI authenticated
- Telegram bot token

## Setup

```bash
chmod +x install.sh
./install.sh
```

Edit `.env` with your tokens, then run:

```bash
node bot.js
```

## Commands

| Command | Description |
|---------|-------------|
| `/status` | Full status report (Issues #45, PRs, VPS) |
| `/prs` | List open PRs across repos |
| `/blockers` | Show blocked/high-priority PRs |
| `/last` | Last comment on Issue #45 |

## Systemd

```bash
sudo cp asdev-bot.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable asdev-bot
sudo systemctl start asdev-bot
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TELEGRAM_BOT_TOKEN` | Yes | Telegram bot token |
| `GITHUB_TOKEN` | No | GitHub fine-grained read-only token |
| `AUDIT_REPO` | No | Defaults to `auditsystems` |
| `BRAND_REPO` | No | Defaults to `AliRezaSafaeiSystems` |

## Architecture

Single-file bot (`bot.js`) using:
- `node-telegram-bot-api` for Telegram
- `gh` CLI for GitHub API calls
- `systemctl` for VPS status

No LLM, no paid APIs, read-only access.
