# ASDEV Current State

**Updated:** 2026-07-10T05:30:00Z
**Mode:** Autonomous Loop Governance **INSTALLED** (GitHub SoT)

---

## Multi-agent (OWNER_PC)

**Updated:** 2026-07-09T15:25:00Z  
**Orchestrator:** Grok · AUTO LOOP ON · complete work first / deploy last  
**Assistants active pattern:** `mimo` + `opencode` (non-interactive worktrees)  
**Policy:** `docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md`  
**Product pin advanced:** `persiantoolbox@72d4209` (post-quality session; deploy still last)

## Platform

| Item | Value |
|------|-------|
| SoT | GitHub `main` |
| Workspace | `/home/dev13/ASDEV` |
| Control plane | `control-plane/` live |
| Loop policy | `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md` |
| Post-deploy live verification policy | `docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md` — mandatory for every production deploy |
| Productivity mode | ENABLED |

## CRITICAL_SITE (`persiantoolbox`)

| Item | Value |
|------|-------|
| Public product | LIVE on public VPS (ubuntu · nginx · PM2 green:3003) release `37ba347` |
| ASDEV IRAN app-layer | Separate host `:3100` (not DNS public) |
| Product GitHub | advanced to `72d4209` after MiMo quality/a11y/SEO/ops session — ahead of live `37ba347` |
| Product score | GitHub quality improved materially; public score is still not 10/10 until deploy, smoke, CWV, uptime evidence, rollback evidence, and live browser verification are verified |
| Staging | public staging + ASDEV legacy paths |
| Rollback history | rehearsal assets added; real production rollback history still needs verified release cycle |
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
| Hermes Telegram | Operational — bot connected to ASDEV Telegram channel |
| Hermes proxy | SOCKS5 tunnel via local xray — systemd user service auto-restart |
| OpenClaw gateway | Active — MCP gateway on port 18789, Telegram disabled |
| OpenClaw bot | Removed — duplicate service caused Telegram polling conflict |

## Gated (not running)

- Public edge  
- Live monitoring timers  
- Migrations  
- Production redeploy  
- Rollback  

## Mandatory post-deploy rule

| Item | Value |
|------|-------|
| Rule | Deployment is not complete until real live public verification passes |
| Required evidence | real browser desktop + mobile, console errors, network failures, route/tool/journey checks, runtime logs, rollback target |
| Required verdicts | LIVE_VERIFICATION_PASS / PASS_WITH_WARNINGS / FAIL_ROLLBACK_RECOMMENDED / FAIL_HOTFIX_REQUIRED / DEPLOY_BLOCKED_NOT_VERIFIED |
| Agent instruction | Refactor deploy scripts so success cannot be printed before live verification passes |
| Applies to | PersianToolbox, AuditSystems, Novax, ASDEV public sites, MCP/public endpoints where applicable |

## Active build focus

ASDEV Engineering Operating System (governance, memory, registry, deploy model, observability prep) — not daily hygiene thrash.

Quality note: Product-side quality packs advance trust/report depth on GitHub main; public score must not be called 10/10 until edge/deploy evidence, depth, CWV, uptime, rollback, and live browser verification are proven.

## PERSIANTOOLBOX QUALITY SESSION (2026-07-09)

| Item | Value |
|------|-------|
| Repo | `alirezasafaei-dev/persiantoolbox` |
| Latest recorded commit | `72d4209` |
| Session scope | a11y, SEO/UX, design tokens, blog size, ops runbooks, monitoring, rollback rehearsal, Zarinpal callback fix |
| Reported validation | typecheck passed; tests reported 153/153 files and 1277/1277 tests |
| Docs updated | `CHANGELOG.md`, `docs/PRODUCTION_GRADE_ROADMAP_TO_10.md` |
| Status | GitHub main advanced; public deploy must remain gated until independent deploy-readiness/smoke/live-browser verification |
| Next safe action | independent post-batch verification + deploy readiness report, no production cutover |

## CONVERSION IMPROVEMENTS (2026-07-09)

| Change | Status |
|--------|--------|
| Fixed broken audit readiness links (external audit domain) | done |
| Added audit CTAs to all 6 case study detail pages | done |
| Added audit readiness to sitemap (priority 0.85) | done |
| Added 'Audit Readiness' to header nav + footer quick links | done |
| Added 'Start Free Audit' CTA to thank-you page | done |
| Admin dashboard: full lead detail dialog, search, filter, live stats | done |
| Services page: added Technical Audit as first offer + audit CTA section | done |
| Created Dialog UI component | done |
| Server: removed duplicate openclaw-bot.service | done |
| Server: disabled OpenClaw Telegram polling via empty token drop-in | done |
| Server: verified Hermes sends messages despite cosmetic conflict warnings | done |

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
| Status | Deployed & merged to `main` |
| Commit | `216534d` |
| Branch | `audit/novax-bot-payments-analytics-deploy` → `main` |
| Worker URL | `https://novax-telegram-relay.asdevelooper.workers.dev` |
| /health | `status=ok`, `service=telegram-bot`, `alert_storage=d1` |
| Telegram bot | webhook set with `secret_token`, 0 pending |
| KV fix | Update dedup moved to in-memory (Set + 120s TTL) to avoid free-tier 1000 writes/day limit |
| Key features | Group payment leakage fix, receipt/admin notification, analytics foundation, admin stats, mini-app tracking, D1 alert storage |
| Audit report | `docs/audit/NOVAX_PRODUCTION_READINESS_AUDIT_2026-07-09.md` |
| Deploy decision | `docs/ops/NOVAX_DEPLOYMENT_DECISION_2026-07-09.md` |
| Repo | `alirezasafaei-dev/novax-price-alert` |
