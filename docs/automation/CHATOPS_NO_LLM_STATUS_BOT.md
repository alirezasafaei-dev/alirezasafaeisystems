# No-LLM Telegram Status Bot

**Status:** Built, awaiting deployment
**Date:** 2026-07-07

## Overview

A simple Telegram bot that reads GitHub API data and returns structured ASDEV status. No LLM required. No paid API.

## Commands

| Command | Description |
|---|---|
| /status | Full status report (VPS timer, PRs, blockers) |
| /prs | List open PRs in alirezasafaeisystems and auditsystems |
| /blockers | Show current blockers |
| /last | Last Issue #45 comment |

## Architecture

- Node.js bot using node-telegram-bot-api
- Reads data via `gh` CLI (GitHub CLI)
- No LLM inference
- No paid API provider
- Read-only GitHub access

## Required Secrets

| Secret | Purpose |
|---|---|
| TELEGRAM_BOT_TOKEN | Telegram bot API |
| GITHUB_TOKEN | Fine-grained token (read-only) |

## GitHub Token Permissions

Fine-grained token with:
- Metadata: read
- Contents: read
- Issues: read
- Pull requests: read

Must NOT include:
- Contents write
- Workflow write
- Deploy access
- PersianToolbox access

## Deployment

1. `bash scripts/telegram-bot/install.sh`
2. Configure `.env` with tokens
3. `systemctl --user enable --now asdev-bot`
4. Test: send `/status` to bot

## Safety

- No LLM: $0 cost
- No command execution
- No repo write
- No deploy
- No PersianToolbox access
- No secrets in repo
