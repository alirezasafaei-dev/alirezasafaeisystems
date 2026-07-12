# ASDEV Current State

**Updated:** 2026-07-12T16:35:00Z  
**Mode:** Autonomous Loop Governance **INSTALLED** (GitHub SoT)

---

## Multi-agent (OWNER_PC / LOCAL_PC)

**Updated:** 2026-07-10T14:58:00Z  
**Canonical name:** `LOCAL_PC` = owner workstation  
**Orchestrator:** MiMo primary commander on LOCAL_PC  
**Implementation agent:** OpenCode  
**Reporting agent:** Hermes  
**OpenClaw:** gateway/diagnostic only; Telegram polling disabled while Hermes owns Telegram  
**Policy:** `docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md` + `docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md`  
**AI Gateway:** Local-first MVP passed on `LOCAL_PC`; GitHub commit `7f3ac55`; automation rollout remains gated

## Platform

| Item | Value |
|------|-------|
| SoT | GitHub `main` |
| Workspace | `/home/dev13/ASDEV` |
| Control plane | `control-plane/` live |
| Loop policy | `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md` |
| Environment roles policy | `docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md` — mandatory |
| GitHub/local/server sync | `docs/ops/GITHUB_LOCAL_SERVER_SYNC.md` + `scripts/control-plane/sync-github-local-server.sh` |
| Sync timer target | `asdev-github-sync.timer` every 5 minutes/10 minutes on `AUTOMATION_SERVER` |
| Post-deploy live verification policy | `docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md` — mandatory for every production deploy |
| AI Gateway policy | `docs/governance/ASDEV_AI_GATEWAY_POLICY.md` — local-first internal infrastructure |
| Productivity mode | ENABLED |

## Environment map

| Canonical name | Meaning | Status |
|------|---------|--------|
| `LOCAL_PC` | Owner's computer; MiMo command center; OpenCode implementation target | AI Gateway local-first MVP passed |
| `AUTOMATION_SERVER` | External server `asdev@91.107.153.223`; loops, MCP, GitHub sync, agents, reports | Operational; AI Gateway automation rollout not approved yet |
| `IRAN_PROD_SERVER` | Iran live production deployment server | Strictly gated; no deploy/rollback/reload/migration without exact approval |
| `GITHUB_MAIN` | GitHub main branch source of truth | Authoritative for prompts/policies/queues/scripts |

## ASDEV AI GATEWAY (LOCAL-FIRST)

| Item | Value |
|------|-------|
| Status | LOCAL_AI_GATEWAY_MVP_PASS on `LOCAL_PC` |
| Latest commit | `7f3ac55` — `feat(ai-gateway): local-first MVP — provider health + task router + docs` |
| Policy | `docs/governance/ASDEV_AI_GATEWAY_POLICY.md` |
| Registry | `docs/ops/ASDEV_AI_PROVIDER_REGISTRY.md` |
| Guide | `docs/ops/ASDEV_AI_GATEWAY_LOCAL_MVP.md` |
| Config example | `config/ai-providers.example.json` |
| Provider health script | `scripts/ai-router/provider-health.sh` |
| Task router script | `scripts/ai-router/run-task.sh` |
| OpenCode prompt | `prompts/opencode/LOCAL_AI_GATEWAY_MVP.md` |
| Sample tasks | `prompts/ai-router/sample-provider-health.md`, `sample-code-patch.md`, `sample-repo-audit.md` |
| Final report | `docs/reports/ai-router/LOCAL_AI_GATEWAY_MVP_20260710T145439Z.md` |
| Validation | `bash -n` checks passed; provider-health passed; router dry-run passed; safe local execute passed; unsafe execute refused |
| Provider status | MiMo/OpenCode/Hermes/OpenClaw available on `LOCAL_PC`; DeepSeek disabled by policy; local small model disabled |
| Production impact | none; no `IRAN_PROD_SERVER`, no deploy, no automation server mutation |
| Secrets | no secrets committed; `.state/ai-router/` gitignored |
| Automation handoff | Requires owner approval `APPROVE_AI_GATEWAY_AUTOMATION_ROLLOUT` |
| Public product gate | Requires separate owner approval `APPROVE_PUBLIC_AI_CHAT_PRODUCT` after PersianToolbox revenue stabilization |

## CRITICAL_SITE (`persiantoolbox`)

| Item | Value |
|------|-------|
| Public product | LIVE on public VPS (ubuntu · nginx · PM2 green:3003) release `37ba347` |
| ASDEV IRAN app-layer | Separate host `:3100` (not DNS public) |
| Product GitHub | advanced to `72d4209` after MiMo quality/a11y/SEO/ops session — ahead of live `37ba347`; later stabilization commits exist in repo |
| Product score | GitHub quality improved materially; public score is still not 10/10 until deploy, smoke, CWV, uptime evidence, rollback evidence, and live browser verification are verified |
| Staging | public staging + ASDEV legacy paths |
| Rollback history | rehearsal assets added; real production rollback history still needs verified release cycle |
| Meta backup | IRAN daily 03:15 UTC · FRESH |

## AUTOMATION_SERVER

| Item | Value |
|------|-------|
| Class | OPERATIONAL — zero-touch autonomous loop active |
| Repo | `/home/asdev/repos/alirezasafaeisystems` |
| Branch | `main` (detached HEAD resolved) |
| Control plane | `scripts/control-plane/` — scripts synced from GitHub |
| Agent loop | `asdev-agent-loop.timer` — enabled, 10min interval, active |
| GitHub sync | `asdev-github-sync.timer` — enabled, 5min interval, active — hardened v2 script |
| Supervisor | `asdev-supervisor.timer` — enabled, 5min interval — pre-loop health gate (git/MCP/disk/memory/network) — verdict: GO (18 PASS, 1 WARN, 0 FAIL) |
| Auto-commit | Working — report files committed and pushed automatically |
| Divergence | Auto-healed with recovery branch; protected on `main` only |
| Detached HEAD | Auto-healed by supervisor; sync script refuses auto-commit on detached HEAD |
| Sync script | `sync-github-local-server.sh` v2 — checks branch, dirty state, divergence before any action |
| Linger | enabled (loginctl enable-linger asdev) |
| Health monitor | `asdev-health-monitor.timer` — enabled, 5min interval, active |
| MCP monitor | `asdev-mcp-monitor.timer` — enabled, 10min interval, active |
| Node | bot.js **disabled** (2026-07-12) — Telegram conflict resolved; Hermes is sole Telegram owner |
| Hermes Telegram | Operational — sole Telegram polling owner (bot.js stopped, Telegram 409 resolved) |
| Issue #45 wiring | Command bus now integrated into agent-loop via `issue45-command-bus.sh` |
| Supervisor asdev-bot | Moved from `critical_units` to `optional_units` — absence causes WARN not FAIL/NO_GO |
| Hermes proxy | SOCKS5 tunnel via local xray — systemd user service auto-restart |
| OpenClaw gateway | Active — MCP/gateway/diagnostic only, Telegram disabled |

## Gated (not running)

- Public edge  
- Live monitoring timers  
- Migrations  
- Production redeploy  
- Rollback  
- `IRAN_PROD_SERVER` production mutations  
- AI Gateway automation rollout  
- Public AI chat product  

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

ASDEV Engineering Operating System plus local-first AI Gateway. PersianToolbox remains in revenue stabilization/freeze stage, not general feature expansion.

Quality note: Product-side quality packs advance trust/report depth on GitHub main; public score must not be called 10/10 until edge/deploy evidence, depth, CWV, uptime, rollback, and live browser verification are proven.

## PERSIANTOOLBOX FINAL REVENUE STABILIZATION (2026-07-10)

| Item | Value |
|------|-------|
| Repo | `alirezasafaei-dev/persiantoolbox` |
| Latest commit | `34f41f4` (suppressHydrationWarning) |
| Verdict | LIVE_VERIFICATION_PASS |
| Tests | 153/153 files, 1277/1277 tests passing |
| Typecheck | Passing |
| Browser test | 34/34 pages pass (Playwright real browser) |
| Payment | ZARINPAL_MERCHANT_ID configured, mode=production, sandbox=false |
| Admin | Funnel stubs replaced with live API, monetization wired to DB |
| Performance | SSR architecture, JS 8.1MB lazy-loaded, CSS 115KB |
| A11y | 433 aria-labels, consent v2, popup pressure gated |
| Deploy fix | Symlink update moved to Step 6 (before nginx reload) |
| Deploy verify | All JS chunks checked, not just first 5 |
| Hydration | suppressHydrationWarning added to html tag |
| AUTOMATION_HOST | 4 timers active, linger enabled |

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
| Server: disabled asdev-bot.service (Telegram conflict resolved) | 2026-07-12 |
| Server: wired Issue #45 command-bus into agent-loop | 2026-07-12 |
| Server: moved asdev-bot to optional supervisor checks (NO_GO→GO) | 2026-07-12 |

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
