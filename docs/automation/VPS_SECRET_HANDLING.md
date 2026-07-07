# VPS Secret Handling — ASDEV Autonomous Agent

**Status:** Ready
**Date:** 2026-07-07

## Required Secrets

| Secret | Purpose | Minimum Scopes |
|---|---|---|
| `GITHUB_TOKEN` | GitHub API, git push | repo, read:org, workflow |
| `SESSION_SECRET` | Auth sessions | random 32+ chars |
| `TELEGRAM_BOT_TOKEN` | Bot notifications (optional) | bot API token |
| `TELEGRAM_CHAT_ID` | Notification target | chat ID |

## Where to Put Secrets

Create `/home/asdev/.env` on VPS:

```bash
touch /home/asdev/.env
chmod 600 /home/asdev/.env
```

Add entries:

```bash
GITHUB_TOKEN=ghp_xxxxxxxxxxxx
SESSION_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TELEGRAM_BOT_TOKEN=123456:ABC-DEF
TELEGRAM_CHAT_ID=-100xxxxxxxxxx
```

## File Permissions

```bash
chmod 600 /home/asdev/.env
chown asdev:asdev /home/asdev/.env
```

## Never

- Commit `.env` to git
- Print `.env` contents
- Share `.env` over chat/email
- Store secrets in scripts
- Use `echo $SECRET` in logs

## GitHub Token Scopes

Minimum required:
- `repo` — clone/push private repos
- `read:org` — org membership checks
- `workflow` — trigger workflows (optional)

Create at: https://github.com/settings/tokens

## Telegram Token Storage

1. Create bot via @BotFather
2. Copy token
3. Add to `/home/asdev/.env`
4. Test: `curl https://api.telegram.org/bot$TOKEN/getMe`

## Token Rotation

1. Generate new token
2. Update `.env`
3. Restart service: `systemctl --user restart asdev-agent-loop.service`
4. Revoke old token at github.com/settings/tokens

## Verify Without Printing

```bash
# Check if token exists and is valid
source /home/asdev/.env
gh auth status
curl -s https://api.github.com/rate_limit | jq .rate.remaining
```

Never do: `cat /home/asdev/.env` or `echo $GITHUB_TOKEN`
