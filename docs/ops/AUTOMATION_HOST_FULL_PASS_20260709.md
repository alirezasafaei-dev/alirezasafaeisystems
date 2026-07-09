# AUTOMATION_HOST Full Pass Report — 2026-07-09

**Host:** `asdev` (AUTOMATION_HOST ≡ OWNER_PC)  
**Executor:** Grok orchestrator  
**Mode:** ordered full pass (Telegram → cron/loop → dispatch → multi-agent)

---

## 1) Hermes Telegram network

### Root cause
- System DNS for `api.telegram.org` resolves to poisoned address `10.10.34.35` (not Telegram).
- Hermes/OpenClaw systemd units had **no proxy** while interactive shell used xray `127.0.0.1:10808`.
- Direct Bot API failed; via SOCKS `getMe` returned **200** for bot `asdevhhbot`.

### Fix applied
| Change | Location |
|--------|----------|
| `TELEGRAM_PROXY=socks5h://127.0.0.1:10808` (+ HTTP/HTTPS/ALL_PROXY) | `~/.hermes/.env` |
| systemd drop-in proxy | `~/.config/systemd/user/hermes-gateway.service.d/proxy.conf` |
| OpenClaw proxy drop-in | `~/.config/systemd/user/openclaw-gateway.service.d/proxy.conf` |
| **Disable OpenClaw Telegram** (same bot hash as Hermes → getUpdates conflict) | `~/.openclaw/openclaw.json` `channels.telegram.enabled=false` |

### Result
- Hermes gateway: **active**
- OpenClaw gateway: **active** (local agents only; no TG poll)
- Residual: occasional shutdown “Chat not found”; recommend live `/start` test in Telegram

---

## 2) Cron / loop (safe only)

| Mechanism | Schedule | Command |
|-----------|----------|---------|
| `asdev-agent-loop.timer` | every 30m | `loop-once.sh` + heartbeat |
| `asdev-control-plane-health.timer` | hourly | health check + queue-list |
| Hermes cron `asdev-control-plane-loop` | every 30m | `~/.hermes/scripts/asdev-loop-once.sh` (no-agent) |

Units stored under `ops/systemd/` (paths fixed from legacy `my-project`).

**Safety:** `queue-claim.sh` skips `approval_required` tasks. `loop-once` only auto-completes `safe-auto` tags.

---

## 3) Queue dispatch

| Task | Result |
|------|--------|
| Edge prep / reviews / control-plane maturity (approved) | **done** + docs |
| Daily health hygiene | **done** via loop-once |
| Public edge / timers / migration / prod deploy | **still pending** (gated — no phrase) |

Deliverables:
- `sites/live/persiantoolbox/docs/ops/VERIFIED_REVIEWS_PROCESS.md` (pushed product main)
- `docs/automation/CONTROL_PLANE_RUNTIME_STATUS_20260709.md`

---

## 4) Multi-agent

- Pattern: `docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md`
- mimo + opencode relaunched for remaining a11y / internal-links (worktrees)
- OpenCode: avoid nested Explore agents (prior hang)

---

## Access matrix (confirmed)

| Target | Access |
|--------|--------|
| Local control-plane | yes |
| Hermes CLI + gateway | yes |
| OpenClaw gateway | yes |
| Public VPS `ubuntu@193.93.169.32` | yes (SSH) |
| Gated prod mutations | no (by design) |

---

## Next owner phrases (if desired)

```
APPROVE_CRITICAL_SITE_PUBLIC_EDGE
APPROVE_MONITORING_LIVE_TIMERS
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
