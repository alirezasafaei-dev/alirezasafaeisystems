# Hermes Capability Review — ASDEV Multi-Agent Orchestration

**Date:** 2026-07-06  
**Reviewer:** ASDEV automation architect (local inspection)  
**Gate:** Required before n8n MVP implementation  
**Install path:** `/home/dev13/.local/bin/hermes`  
**Project:** `/home/dev13/.hermes/hermes-agent`  
**Version:** Hermes Agent v0.17.0 (2026.6.19)

---

## 1. How Hermes is installed and invoked

| Item | Finding |
|---|---|
| Binary | `/home/dev13/.local/bin/hermes` (Python entrypoint) |
| Invoke | `hermes`, `hermes chat`, `hermes -z "prompt"` (oneshot), `hermes --tui` |
| Config | `~/.hermes/config.yaml`, `~/.hermes/.env` |
| Profiles | `hermes profile list|use|create` — isolated agent instances |
| Worktrees | `hermes --worktree` / `hermes -w` — parallel agents in git worktrees |
| Dashboard | `hermes dashboard` (web UI, port 9119) |
| Service | `hermes gateway start` (systemd user unit exists: `hermes-gateway.service`) |

**Default model (this machine):** `openrouter/owl-alpha` via OpenRouter.

---

## 2. Help / docs surface (orchestration-relevant)

Core subcommands inspected:

| Command | Purpose for ASDEV |
|---|---|
| `hermes cron` | Scheduled agent runs (`create`, `list`, `tick`, `pause`) |
| `hermes webhook` | Event-driven runs (`subscribe`, GitHub-style payload templates) |
| `hermes kanban` | **SQLite task board** — claim, dispatch, swarm, multi-profile workers |
| `hermes gateway` | Messaging + dispatcher integration |
| `hermes hooks` | Shell hooks on events (approval/consent via allowlist) |
| `hermes send` | Notify owner without LLM (Telegram/Discord/Slack) |
| `hermes sessions` | Session history, resume, export |
| `hermes -z PROMPT` | Scriptable one-shot agent (CI/automation friendly) |

Upstream doc reference (local): `~/.hermes/hermes-agent/hermes-already-has-routines.md` — documents cron + GitHub webhooks + delivery including GitHub comments.

---

## 3. Capability matrix vs ASDEV needs

| Capability | Hermes | Notes |
|---|---|---|
| Task routing | ✅ Strong | `kanban dispatch`, `swarm`, profile-based assignees |
| Queues | ✅ | Kanban SQLite board with claim/ready/blocked/scheduled |
| Approvals | ⚠️ Partial | Hook allowlist + interactive prompts; not GitHub-native approval UI |
| GitHub comments | ⚠️ Possible | Documented as webhook delivery target; **GitHub API key not configured** on this machine (`hermes status`) |
| Reports | ✅ | Kanban `comment`, `complete`, worker logs, `hermes send` |
| Schedules | ✅ | `hermes cron` (cron expressions + human intervals) |
| Multi-agent orchestration | ✅ Strong | Kanban + profiles + worktrees + swarm graphs |
| PR/issue polling | ⚠️ Indirect | Via `webhook subscribe` (needs GitHub webhook → Hermes) or external poller |
| Owner notifications | ✅ | Telegram configured on this machine |
| Model routing | ✅ | Per-profile model/provider; fallback chain |
| ASDEV focus enforcement | ❌ None built-in | Must inject via prompt + `AGENTS.md` + external gates |

---

## 4. Hermes vs n8n for ASDEV workflow

| Dimension | Hermes | n8n |
|---|---|---|
| **Agent execution** | Native (tool-calling agent loop) | External — must shell out to CLIs |
| **Multi-agent tasks** | Kanban + profiles + dispatch | Manual workflow nodes per agent |
| **Cron / schedules** | Built-in | Built-in |
| **GitHub triggers** | Webhook subscriptions | GitHub trigger node |
| **Visual ops dashboard** | `dashboard`, `kanban watch` | Strong visual editor |
| **Approval gates** | Hooks + manual; weak PR integration | Easy human-in-the-loop nodes |
| **Report normalization** | Custom (kanban comments / deliver) | Easy JSON transform + GitHub node |
| **Learning curve** | Agent-native; steeper CLI | Familiar no-code routing |
| **Risk** | Agent can edit code if prompted | Router-only if designed correctly |
| **Cost** | API keys per agent run | Self-hosted + agent costs |

### Hermes strengths for ASDEV

1. **Already installed** and running-class tooling (cron, webhook, kanban, gateway).
2. **True multi-agent orchestration** without gluing 8 CLIs manually.
3. **Kanban dispatch** matches "task proposed → assigned → running → reported".
4. **Worktree isolation** fits multi-repo ASDEV workspace.
5. **Telegram delivery** already configured for owner alerts.

### Hermes gaps for ASDEV

1. **GitHub is not wired** on this machine (no GitHub API key in `hermes status`).
2. **PR #42 command-center protocol** is custom — needs thin adapter (poll script → kanban task or `hermes -z`).
3. **Owner approval gates** are not as explicit as a dedicated workflow UI.
4. **PersianToolbox protection** must be policy-injected — Hermes will not enforce alone.

### n8n strengths (if added later)

1. **Pure router** — hard separation: n8n never edits code.
2. **Visual approval branches** — owner review before spawn.
3. **GitHub polling node** — complements PR #42 monitor without agent session.
4. **Notification fan-out** — email, Slack, Telegram, GitHub in one place.

### n8n gaps

1. Does not run agents — adds moving parts.
2. Another service to host/secure (Postgres, encryption key, tokens).
3. Risk of over-automation if workflows bypass approval.

---

## 5. Recommendation

### ✅ Primary: **Hermes + thin GitHub adapter (hybrid-lite)**

Use Hermes as the **execution orchestrator**:

```text
GitHub PR #42 / issue
  → monitor script OR Hermes webhook
  → kanban task (status, repo_scope, approval_required)
  → owner approval gate (Telegram / manual PR comment)
  → hermes kanban dispatch → profile (Codex/Grok/Gemini/…)
  → agent runs in worktree
  → report → PR comment (via gh CLI or Hermes deliver when GitHub key set)
  → owner / ChatGPT → next prompt
```

Add **n8n only if** after 2 weeks:

- GitHub ↔ Hermes glue remains painful, OR
- Owner wants visual approval dashboard non-developers can edit, OR
- Notification routing exceeds Hermes `send` + Telegram.

### ❌ Not recommended now

- **n8n-only** — duplicates agent execution Hermes already does; more latency.
- **Hermes-only with zero GitHub adapter** — PR #42 protocol would still need manual relay.

### Minimum next setup steps (no production deploy)

1. Configure **GitHub token** in Hermes (or keep `gh` CLI in kanban worker scripts).
2. Map **PR #42 monitor** → kanban `create` on `PROMPT_PENDING`.
3. Define **Hermes profiles**: `asdev-codex`, `asdev-grok`, `asdev-gemini`, `asdev-docs`.
4. Encode **PersianToolbox guard** in task body template (read-only default).
5. Defer `ops/n8n/` until owner confirms n8n slice needed.

---

## 6. ASDEV Audit goal alignment

This review supports:

- **Lower audit cost / execution time** — faster agent routing, less owner relay
- **Better production reliability** — explicit gates, no auto-deploy
- **More submitted audits** — indirect via faster implementation cycles on `auditsystems`

It does **not** directly change product code.

---

## 7. Decision requested from owner

Reply on PR #42 with one of:

- `Approved: Hermes hybrid-lite — proceed with kanban + GitHub adapter docs`
- `Approved: n8n hybrid — proceed with full automation doc package`
- `Approved: Hermes-only — no n8n`
- `Hold — no automation expansion yet`