# ASDEV Current State

**Updated:** 2026-07-09T17:45:58Z  
**Mode:** Autonomous Loop Governance **INSTALLED** (GitHub SoT)

---

## Multi-agent (OWNER_PC)

**Updated:** 2026-07-09T15:25:00Z  
**Orchestrator:** Grok · AUTO LOOP ON · complete work first / deploy last  
**Assistants active pattern:** `mimo` + `opencode` (non-interactive worktrees)  
**Policy:** `docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md`  
**Product pin advanced:** `persiantoolbox@d0ae88f` (inspect scrub for PM2; deploy still last)

## Platform

| Item | Value |
|------|-------|
| SoT | GitHub `main` |
| Workspace | `/home/dev13/ASDEV` |
| Control plane | `control-plane/` live |
| Loop policy | `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md` |
| Productivity mode | ENABLED |

## CRITICAL_SITE (`persiantoolbox`)

| Item | Value |
|------|-------|
| Public product | LIVE on public VPS (ubuntu · nginx · PM2 green:3003) release `37ba347` |
| ASDEV IRAN app-layer | Separate host `:3100` (not DNS public) |
| Product GitHub | advanced (`9c8b626`+ quality/SEO/blog packs) — may be ahead of live `37ba347` |
| Product score | ~7.5–8.0/10 est. · not 10/10 |
| Staging | public staging + ASDEV legacy paths |
| Rollback history | none (first prod) |
| Meta backup | IRAN daily 03:15 UTC · FRESH |

## AUTOMATION_HOST

| Item | Value |
|------|-------|
| Class | OPERATIONAL — zero-touch autonomous loop active |
| Control plane | `~/asdev-platform/control-plane/` — scripts synced from repo |
| Agent loop | `asdev-agent-loop.timer` — enabled, 10min interval, active |
| Loop behavior | Self-feeding: health check → MCP check → auto-commit → auto-push → queue seed when only gated tasks remain |
| Linger | enabled (user systemd persistent) |
| Repo clone | `~/repos/alirezasafaeisystems` — main, up to date |
| Cron | `asdev-meta-backup.sh` daily 03:15 UTC |
| Node | bot.js running (Issue #45 command bus) |
| Last loop commit | `b6c960c` (self-task.sh enhanced with MCP health, queue seeding, port checks) |
| Hardening commit | `ba07235` (robust memory timestamp + JSON queue safe-task seeding) |

## Gated (not running)

- Public edge  
- Live monitoring timers  
- Migrations  
- Production redeploy  

## Active build focus

ASDEV Engineering Operating System (governance, memory, registry, deploy model, observability prep) — not daily hygiene thrash.

Quality note: Product-side quality packs advance trust/report depth on github main; public score remains ~7.5 until edge is live and measured. Do not claim 10/10 or public prod edge deploy until edge + depth + uptime are proven.

## MCP SERVER (ASDEV GitHub Assistant)

| Item | Value |
|------|-------|
| Status | Operational |
| Commit | `d261bdd` (on `main`) |
| Endpoint | `https://mcp.alirezasafaeisystems.ir/sse/` |
| TLS | Let's Encrypt (auto via Caddy) |
| Runtime | systemd (`asdev-chatgpt-mcp` + `asdev-chatgpt-caddy`) |
| Host | automation server |
| Tools | 6 read-only (list_repositories, get_repository_summary, search_code, read_file, list_issues, list_pull_requests) |
| Auth | None (private testing) |
| ChatGPT | Connected, app built, tools/list verified |
| PR #89 | Closed — superseded by `d261bdd` |
| Next risk | Add OAuth for production use |
| Docs | `docs/ops/CHATGPT_MCP_CONNECTOR.md` |

## NOVAX AUDIT (Cloudflare Worker Bot)

| Item | Value |
|------|-------|
| Status | ✅ Deployed & merged to `main` |
| Commit | `216534d` |
| Branch | `audit/novax-bot-payments-analytics-deploy` → `main` |
| Worker URL | `https://novax-telegram-relay.asdevelooper.workers.dev` |
| /health | `{"status":"ok","service":"telegram-bot","alert_storage":"d1"}` |
| Telegram bot | @novax_price_bot — webhook set with `secret_token`, 0 pending |
| KV fix | Update dedup moved to in-memory (Set + 120s TTL) to avoid free-tier 1000 writes/day limit |
| Key features | Group payment leakage fix, receipt/admin notification, analytics foundation, admin stats, mini-app tracking, D1 alert storage |
| Audit report | `docs/audit/NOVAX_PRODUCTION_READINESS_AUDIT_2026-07-09.md` |
| Deploy decision | `docs/ops/NOVAX_DEPLOYMENT_DECISION_2026-07-09.md` |
| Repo | `https://github.com/alirezasafaei-dev/novax-price-alert.git` |
