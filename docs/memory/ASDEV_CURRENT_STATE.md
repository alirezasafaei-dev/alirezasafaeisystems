# ASDEV Current State

**Updated:** 2026-07-10T08:10:00Z
**Mode:** Autonomous Loop Governance **INSTALLED** (GitHub SoT)

---

## Multi-agent (OWNER_PC / LOCAL_PC)

**Updated:** 2026-07-10T08:10:00Z  
**Canonical name:** `LOCAL_PC` = owner workstation  
**Orchestrator:** MiMo primary commander on LOCAL_PC  
**Implementation agent:** OpenCode  
**Reporting agent:** Hermes  
**OpenClaw:** gateway/diagnostic only; Telegram polling disabled while Hermes owns Telegram  
**Policy:** `docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md` + `docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md`  
**Product pin advanced:** `persiantoolbox@72d4209` plus later hotfix commits; deploy/live verification remains gated

## Platform

| Item | Value |
|------|-------|
| SoT | GitHub `main` |
| Workspace | `/home/dev13/ASDEV` |
| Control plane | `control-plane/` live |
| Loop policy | `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md` |
| Environment roles policy | `docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md` — mandatory |
| GitHub/local/server sync | `docs/ops/GITHUB_LOCAL_SERVER_SYNC.md` + `scripts/control-plane/sync-github-local-server.sh` |
| Sync timer target | `asdev-github-sync.timer` every 5 minutes on `AUTOMATION_SERVER` |
| Post-deploy live verification policy | `docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md` — mandatory for every production deploy |
| Productivity mode | ENABLED |

## Environment map

| Canonical name | Meaning | Status |
|------|---------|--------|
| `LOCAL_PC` | Owner's computer; MiMo command center | Not looped yet; command/orchestration only |
| `AUTOMATION_SERVER` | External server `asdev@91.107.153.223`; loops, MCP, GitHub sync, agents, reports | Existing loop active; GitHub sync timer rollout required |
| `IRAN_PROD_SERVER` | Iran live production deployment server | Strictly gated; no deploy/rollback/reload/migration without exact approval |
| `GITHUB_MAIN` | GitHub main branch source of truth | Authoritative for prompts/policies/queues/scripts |

## CRITICAL_SITE (`persiantoolbox`)

| Item | Value |
|------|-------|
| Public product | LIVE on public VPS (ubuntu · nginx · PM2 green:3003) release `37ba347` |
| ASDEV IRAN app-layer | Separate host `:3100` (not DNS public) |
| Product GitHub | advanced to `72d4209` after MiMo quality/a11y/SEO/ops session — ahead of live `37ba347`; later deploy hotfixes exist in repo |
| Product score | GitHub quality improved materially; public score is still not 10/10 until deploy, smoke, CWV, uptime evidence, rollback evidence, and live browser verification are verified |
| Staging | public staging + ASDEV legacy paths |
| Rollback history | rehearsal assets added; real production rollback history still needs verified release cycle |
| Meta backup | IRAN daily 03:15 UTC · FRESH |

## AUTOMATION_SERVER

| Item | Value |
|------|-------|
| Class | OPERATIONAL — zero-touch autonomous loop active, sync hardening in progress |
| Control plane | `~/asdev-platform/control-plane/` / repo clone — scripts synced from repo |
| Agent loop | `asdev-agent-loop.timer` — enabled, 10min interval, active |
| GitHub sync | `asdev-github-sync.timer` template + installer created; rollout/verification required on server |
| Loop behavior | Self-feeding: health check → MCP check → auto-commit → auto-push → queue seed when only gated tasks remain |
| Linger | enabled/required (user systemd persistent) |
| Repo clone | `~/repos/alirezasafaeisystems` expected canonical clone |
| Cron | `asdev-meta-backup.sh` daily 03:15 UTC |
| Node | bot.js running (GitHub Issue #45 command bus; must not be mislabeled branch 45) |
| Last loop commit | `b6c960c` (self-task.sh enhanced with MCP health, queue seeding, port checks) |
| Hardening commit | `ba07235` (robust memory timestamp + JSON queue safe-task seeding) |
| Hermes Telegram | Operational — default Telegram reporting owner |
| Hermes proxy | SOCKS5 tunnel via local xray — systemd user service auto-restart |
| OpenClaw gateway | Active — MCP/gateway/diagnostic only, Telegram disabled |
| OpenClaw bot | Removed/disabled if it conflicts with Hermes Telegram polling |

## Gated (not running)

- Public edge  
- Live monitoring timers  
- Migrations  
- Production redeploy  
- Rollback  
- `IRAN_PROD_SERVER` production mutations  

## Mandatory sync rule

| Item | Value |
|------|-------|
| Rule | Prompt/policy/queue files committed to GitHub must become discoverable on `AUTOMATION_SERVER` without manual copy-paste |
| Script | `scripts/control-plane/sync-github-local-server.sh` |
| Installer | `scripts/control-plane/install-github-sync-service.sh` |
| Service | `asdev-github-sync.service` |
| Timer | `asdev-github-sync.timer` |
| Reports | `.state/asdev-sync/latest.json`, `ops/automation-logs/github-sync-latest.log`, `docs/reports/automation-server/latest-github-sync.md` |
| Dirty repo policy | safe reports/state may be committed; unsafe unknown changes block pull and produce drift report; no destructive reset |

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
| Latest recorded quality commit | `72d4209` |
| Later hotfix commits | JS chunk copy + post-deploy verification exist in PersianToolbox main |
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
