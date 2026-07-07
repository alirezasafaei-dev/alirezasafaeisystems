# OpenClaw ChatOps Pilot for ASDEV

**Status:** Phase 1 approved (no-LLM mode)
**Date:** 2026-07-07
**LLM Provider:** UNCONFIGURED — no paid API approved

## What Is OpenClaw

OpenClaw is a personal AI assistant (382k GitHub stars) that runs as a local Gateway daemon. It supports multi-channel messaging (Telegram, Slack, Discord, WhatsApp, Signal, etc.), multi-agent routing, sandboxing, and CLI automation.

## Phase 1: No-LLM Telegram Status Bot

Phase 1 uses OpenClaw as a Telegram bot that reads GitHub API data directly. No LLM is required.

### What Phase 1 Does

- Connects to Telegram (private bot, owner allowlist only)
- Reads Issue #45 latest comments via GitHub API
- Checks open PRs in alirezasafaeisystems and auditsystems
- Returns structured status to Telegram
- No paid API, no LLM inference, no model costs

### What Phase 1 Does NOT Do

- Submit commands to Issue #45 (Phase 2)
- Create or modify PRs
- Deploy to production
- Edit PersianToolbox
- Access billing or schema
- Use any paid LLM provider

## Provider Decision Matrix

| Option | Description | Cost | Status |
|---|---|---|---|
| A: No-LLM | GitHub API only, structured output | Free | **Phase 1 (approved)** |
| B: Local model | OpenClaw with local LLM | Free | Future evaluation |
| C: DeepSeek | OpenClaw with DeepSeek API | Low cost | Requires owner confirmation |
| D: OpenAI API | OpenClaw with OpenAI | $20/month | **NOT approved** |

**Phase 1 uses Option A: No-LLM status bot.**

## Security Model

### Isolation

- Separate OS user: `openclaw` (not `asdev`)
- Separate config: `/home/openclaw/.openclaw/`
- Gateway binds to loopback only (127.0.0.1)
- Sandbox mode (Docker for non-main sessions)

### GitHub Token (Fine-Grained)

Required permissions ONLY:
- Metadata: read
- Contents: read
- Issues: read/write
- Pull requests: read

Must NOT include:
- Workflow write
- Contents write
- Deploy access
- PersianToolbox access
- Broad `repo` scope

### Safety Constraints

- No paid API approved
- No OpenAI API key
- No LLM inference
- No command submission (Phase 1)
- No deploy credentials
- No PersianToolbox access
- No billing/schema access

## Pilot Phases

### Phase 0: Docs-Only Evaluation ✅

- [x] Research OpenClaw architecture
- [x] Create integration design
- [x] Define security model
- [x] Owner approval for Phase 1

### Phase 1: No-LLM Status Bot (Current)

- [ ] Install OpenClaw as `openclaw` user
- [ ] Configure Telegram channel (pairing mode)
- [ ] Add GitHub fine-grained token
- [ ] Install asdev-status skill
- [ ] Test: "status" returns Issue #45 / PR summary
- [ ] Verify: no command submission works

### Phase 2: Command Submitter (Future)

Requires:
- Phase 1 validated
- Owner approval for command submission
- Still no paid LLM required

### Phase 3: PR Assistant (Future)

Requires:
- Phase 2 validated
- Owner approval
- Still read-only for alirezasafaeisystems only

## Required Secrets (Phase 1)

| Secret | Purpose | Storage |
|---|---|---|
| Telegram bot token | Telegram channel | /home/openclaw/.openclaw/openclaw.json |
| GitHub fine-grained token | Issue/PR read | /home/openclaw/.openclaw/openclaw.json |

**No OpenAI API key. No paid LLM provider.**

## Rollback Plan

1. Stop OpenClaw gateway: `openclaw gateway stop`
2. Disable systemd service: `systemctl --user disable openclaw-gateway`
3. Remove openclaw user: `sudo userdel -r openclaw`
4. ASDEV automation continues unaffected

## Cost

- OpenClaw: Free (self-hosted)
- LLM API: $0 (no LLM used)
- Telegram bot: Free
- VPS resources: Minimal (~50MB RAM for gateway)
