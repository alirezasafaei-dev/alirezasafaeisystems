# OpenClaw ChatOps Pilot for ASDEV

**Status:** Evaluation (docs-only)
**Date:** 2026-07-07
**Decision:** Do not install until owner explicitly approves

## What Is OpenClaw

OpenClaw is a personal AI assistant (382k GitHub stars) that runs as a local Gateway daemon. It supports multi-channel messaging (Telegram, Slack, Discord, WhatsApp, Signal, etc.), multi-agent routing, sandboxing, and CLI automation.

Key capabilities relevant to ASDEV:
- Read Issue #45 comments and status
- Post commands to Issue #45 via GitHub API
- Summarize PR and status changes
- Route human chat commands to ASDEV command bus
- Run on VPS as a separate user with limited permissions

## Why Evaluate OpenClaw

| Problem | OpenClaw Solution |
|---|---|
| User copies reports between ChatGPT and MiMo | OpenClaw reads Issue #45 and summarizes |
| No Telegram/Slack integration for ASDEV | OpenClaw connects to Telegram natively |
| Manual command posting | OpenClaw posts ASDEV STATUS automatically |
| No human-friendly status interface | OpenClaw provides chat-based status |

## Architecture Decision

### OpenClaw vs Hermes-Only

| Factor | Hermes-Only | OpenClaw + Hermes |
|---|---|---|
| Command bus | Issue #45 comments | Issue #45 + Telegram/Slack |
| Status reporting | Issue #45 only | Issue #45 + chat channel |
| Human interaction | Copy-paste commands | Natural language chat |
| Complexity | Low | Medium |
| Security surface | Small | Larger (channel integrations) |
| Cost | Free | Free (self-hosted) |
| Maintenance | Minimal | Requires OpenClaw updates |

### Recommendation

Pilot OpenClaw as a ChatOps bridge, not as a core executor.

- OpenClaw reads status and posts commands
- Hermes/VPS runner remains the actual execution layer
- OpenClaw has no direct deploy or write authority
- OpenClaw runs in a sandboxed environment

## Security Model

### What OpenClaw CAN Do

- Read Issue #45 comments and status
- Post ASDEV STATUS, ASDEV RUN, ASDEV STOP commands to Issue #45
- Summarize PR states and VPS timer status
- Connect to Telegram/Slack for human chat
- Route chat commands to ASDEV command bus

### What OpenClaw MUST NOT Do

- Edit PersianToolbox (read-only only)
- Deploy to production
- Access .env files or secrets
- Modify ASDEV runner scripts
- Merge PRs
- Run arbitrary shell commands on VPS
- Access billing/payment systems

### Isolation Requirements

1. Separate OS user: Run OpenClaw as openclaw user, not asdev
2. Separate config: OpenClaw config in /home/openclaw/.openclaw/
3. Limited GitHub token: Only repo:read, issues:write, pull_requests:read
4. No deploy credentials: OpenClaw does not receive VPS deploy keys
5. Sandbox mode: Non-main sessions run in Docker sandbox
6. Network isolation: Gateway binds to loopback only (127.0.0.1)

## Proposed Configuration

### OpenClaw Config

Minimal openclaw.json:
- agent.model: openai/gpt-4o
- agent.workspace: /home/openclaw/.openclaw/workspace
- gateway.host: 127.0.0.1
- gateway.port: 18789
- channels.telegram.enabled: true
- channels.telegram.dmPolicy: pairing
- agents.defaults.sandbox.mode: all
- agents.defaults.sandbox.backend: docker
- tools.allowed: read, sessions_list, sessions_history
- tools.denied: write, edit, bash, process, gateway

### GitHub Token Scopes

Minimum required:
- repo:read (read issues, PRs)
- issues:write (post comments)
- pull_requests:read (read PR status)

Must NOT include:
- repo:write
- admin
- workflow

## Pilot Phases

### Phase 0: Docs-Only Evaluation (Current)

- [x] Research OpenClaw architecture
- [x] Create integration design document
- [x] Define security model
- [x] Define pilot phases
- [ ] Owner review and approval

No installation. No runtime changes.

### Phase 1: Read-Only Status Bot

Condition: Owner approves Phase 0

1. Install OpenClaw as openclaw user on VPS
2. Configure Telegram channel (pairing mode)
3. Create ASDEV skill that reads Issue #45 status
4. OpenClaw posts status summary to Telegram on request
5. No command execution - read-only

Validation:
- OpenClaw starts and connects to Telegram
- Can read Issue #45 comments
- Can summarize PR status
- Cannot execute commands or edit files

### Phase 2: Issue #45 Command Submitter

Condition: Phase 1 validated

1. Add skill that posts ASDEV STATUS to Issue #45
2. Add skill that posts ASDEV RUN to Issue #45
3. Add skill that posts ASDEV STOP to Issue #45
4. User types status in Telegram - OpenClaw posts ASDEV STATUS
5. VPS runner processes the command normally

Validation:
- Telegram command triggers Issue #45 comment
- VPS runner processes the comment
- Status report appears in Issue #45

### Phase 3: Limited PR Assistant (alirezasafaeisystems Only)

Condition: Phase 2 validated

1. Add skill that summarizes open PRs
2. Add skill that reads PR comments
3. Add skill that posts PR status to Telegram
4. NO merge authority - read-only
5. NO access to auditsystems or persiantoolbox repos

Validation:
- Can list open PRs in alirezasafaeisystems
- Can summarize PR changes
- Cannot merge, edit, or push

### Never Granted

- Production deploy authority
- PersianToolbox write access
- Broad filesystem access
- Arbitrary shell execution
- Billing/payment access
- Schema migration access

## Required Secrets (If Pilot Proceeds)

| Secret | Purpose | Storage |
|---|---|---|
| Telegram bot token | Telegram channel | /home/openclaw/.openclaw/openclaw.json |
| GitHub read-only token | Issue/PR access | /home/openclaw/.openclaw/openclaw.json |
| OpenAI API key | LLM provider | /home/openclaw/.openclaw/openclaw.json |

All secrets stored in openclaw user home, chmod 600.
Never committed to git. Never printed.

## Rollback Plan

If OpenClaw causes issues:

1. Stop OpenClaw gateway: openclaw gateway stop
2. Disable systemd service: systemctl --user disable openclaw-gateway
3. Remove openclaw user: sudo userdel -r openclaw
4. ASDEV automation continues unaffected (VPS runner is independent)

## Cost

- OpenClaw: Free (self-hosted)
- LLM API: Pay-per-use (OpenAI/DeepSeek/etc.)
- Telegram bot: Free
- VPS resources: Minimal (~100MB RAM for gateway)

## Decision Required

| Decision | Options |
|---|---|
| Proceed with Phase 1? | Yes / No / Defer |
| Telegram channel? | Yes / No |
| LLM provider | OpenAI / DeepSeek / Local |
| Budget for LLM API | Monthly limit |

No action until owner explicitly approves.
