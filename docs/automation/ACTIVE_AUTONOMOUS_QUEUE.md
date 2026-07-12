# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-10T17:22:00Z  
**Status:** PERSIANTOOLBOX LIVE_VERIFICATION_PASS · AUTOMATION HARDENING #91 COMPLETE · FINAL RELIABILITY #94 ACTIVE

## Runtime
- `LOCAL_PC`: owner's own computer/workstation; MiMo primary commander.
- `AUTOMATION_SERVER`: `asdev@91.107.153.223`; always-on loop, GitHub sync, MCP, queue, reports.
- `IRAN_PROD_SERVER`: live production deployment server; gated.
- Hermes: default Telegram reporting owner.
- OpenClaw: gateway/diagnostic only; Telegram polling disabled unless explicitly approved.

## Mandatory policies
- `docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md`
- `docs/ops/GITHUB_LOCAL_SERVER_SYNC.md`
- `docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md`
- `docs/governance/ASDEV_AI_GATEWAY_POLICY.md`
- Deployment is not done until the real live public site/service has passed real browser verification and operational checks.
- Prompt/policy/queue files committed to GitHub must become discoverable on `AUTOMATION_SERVER` without manual copy-paste.

## Immediate notes
- PersianToolbox: LIVE_VERIFICATION_PASS. 34/34 pages pass in real browser.
- Deploy fix: symlink update moved to Step 6 (before nginx reload) — prevents stale static files.
- Deploy verify: all JS chunks checked, not just first 5.
- Hydration: suppressHydrationWarning added — no more React #418 errors.
- Payment gateway: ZARINPAL_MERCHANT_ID configured, mode=production, sandbox=false.
- Admin: live API calls, monetization wired to DB.
- Development freeze: ready for owner approval.
- AI Gateway local MVP: PASS on LOCAL_PC; automation rollout remains gated.
- Issue #94 is the active infrastructure priority before AI Gateway automation rollout.

## Safe continuous
- GitHub sync every 5 minutes/10 minutes according to installed timer policy.
- loop-once safe-auto drain.
- multi-agent MiMo/OpenCode under explicit environment naming.
- product quality pre-deploy.

## Issue #91 — Automation Server Hardening (P0) — COMPLETE
- [x] Detached HEAD resolved on AUTOMATION_SERVER — branch restored to `main`
- [x] Auto-commits no longer happen on detached HEAD (sync script v2 blocks)
- [x] Divergence preserved with recovery branches (`recovery/auto-*`)
- [x] Sync script v2 deployed — pre-flight checks: branch, dirty state, divergence, rebase/cherry-pick/merge
- [x] Supervisor service & timer installed — checks git state, timers, MCP, disk, memory, network, provider health
- [x] Auto-commit glob bug fixed — `ops/automation-logs/*.summary.md` no longer breaks `git add`
- [x] run-task.sh argument parsing improved — better error messages, relative path resolution
- [x] Report files auto-committed and pushed to GitHub by sync timer
- [x] Recovery commits preserved in `recovery/auto-commits-20260710` and `recovery/auto-divergence-20260710`
- [x] GitHub issue #91 closed as completed

## Issue #94 — Final Reliability Hardening (P1) — ACTIVE
Prompt: `prompts/opencode/AUTOMATION_SERVER_FINAL_RELIABILITY_HARDENING.md`

- [ ] MCP health v2 follows redirects and validates final SSE semantics
- [ ] HTTP `000` is treated as failure, never PASS
- [ ] Supervisor v2 performs bounded allowlisted recovery with cooldown and max attempts
- [ ] Unknown code-bearing Git divergence produces `NO_GO` and is never hard-reset automatically
- [ ] Generated report commits are throttled by semantic state changes
- [ ] Timestamp-only commit storms are eliminated
- [ ] loop-once fails closed on supervisor `NO_GO`
- [ ] Regression fixtures cover MCP, recovery, Git divergence, and throttling
- [ ] Reboot drill runbook prepared
- [ ] Controlled reboot executed only after `APPROVE_AUTOMATION_SERVER_REBOOT_DRILL`
- [ ] Final report committed under `docs/reports/automation-server/`
- [ ] AI Gateway automation remains disabled

## Completed safe cycles
- [x] MCP health monitor report | ID: ASDEV-AUTO-MCP-HEALTH | Mode: read-only | Priority: 3
- [x] Control-plane queue integrity check | ID: ASDEV-AUTO-QUEUE-INTEGRITY | Mode: automation-script | Priority: 3
- [x] Agent memory freshness check | ID: ASDEV-AUTO-MEMORY-FRESH | Mode: docs-only | Priority: 3
- [x] MCP recurring health verify | ID: ASDEV-AUTO-MCP-SSE | Mode: read-only | Priority: 4
- [x] OpenClaw gateway diagnostic only | ID: ASDEV-AUTO-OPENCLAW-DIAG | Mode: read-only | Priority: 5
- [x] Install/enable GitHub sync on `AUTOMATION_SERVER` | ID: ASDEV-AUTO-GITHUB-SYNC-TIMER-INSTALL | Mode: automation-script | Priority: 0
- [x] Verify GitHub sync pulls new prompts without manual copy | ID: ASDEV-AUTO-GITHUB-SYNC-PROMPT-DISCOVERY | Mode: read-only/automation-script | Priority: 0
- [x] Fix stale Telegram/OpenClaw branch/issue status labels using environment roles policy | ID: ASDEV-AUTO-TELEGRAM-STALE-STATUS-FIX | Mode: automation-script | Priority: 1
- [x] Verify PersianToolbox MiMo hotfix with real browsers | ID: ASDEV-AUTO-PTB-MIMO-HOTFIX-BROWSER-VERIFY | Mode: read-only/automation-script | Priority: 1
- [x] Upgrade PersianToolbox post-deploy verification from curl-only to Playwright-backed live verification | ID: ASDEV-AUTO-PTB-LIVE-VERIFY-PLAYWRIGHT | Mode: automation-script | Priority: 1
- [x] Integrate PersianToolbox live verification into deploy-blue-green.sh final success gate | ID: ASDEV-AUTO-PTB-DEPLOY-SUCCESS-GATE | Mode: automation-script | Priority: 1
- [x] P0: PersianToolbox Zarinpal/payment/login-register stabilization | ID: ASDEV-AUTO-PTB-PAYMENT-STABILIZE | Mode: code/test/live-safe | Priority: 0 | Done: payment fixes + health indicator + auth gate
- [x] P0: PersianToolbox admin dashboard real operational audit/fix | ID: ASDEV-AUTO-PTB-ADMIN-OPS-FIX | Mode: code/test/live-safe | Priority: 0 | Done: funnel stubs replaced with live API
- [x] P0/P1: PersianToolbox first-load/cold-load performance and SSR/SSG audit/fix | ID: ASDEV-AUTO-PTB-FIRST-LOAD-FIX | Mode: code/test/live-safe | Priority: 1 | Done: SSR audit complete, TTF removed
- [x] P1: PersianToolbox privacy transparency, analytics/vitals, a11y, popup pressure cleanup | ID: ASDEV-AUTO-PTB-AUDIT-ESSENTIALS | Mode: code/docs/test | Priority: 2 | Done: a11y verified, popup pressure acceptable
- [x] P0: ASDEV AI Gateway local-first MVP with OpenCode | ID: ASDEV-AUTO-AI-GATEWAY-LOCAL-MVP | Mode: LOCAL_PC/opencode/docs+scripts | Commit: `7f3ac55`
- [x] P0: AI provider health and registry verification on LOCAL_PC | ID: ASDEV-AUTO-AI-GATEWAY-PROVIDER-HEALTH | Mode: LOCAL_PC/read-only/script
- [x] P1: AI task router dry-run and safe local execute | ID: ASDEV-AUTO-AI-GATEWAY-TASK-ROUTER | Mode: LOCAL_PC/script

## Safe next cycles
- [ ] P1: Automation Server final reliability hardening | ID: ASDEV-AUTO-FINAL-RELIABILITY-HARDENING | Mode: AUTOMATION_SERVER/opencode/scripts+tests | Priority: 0 | Issue: #94 | Prompt: `prompts/opencode/AUTOMATION_SERVER_FINAL_RELIABILITY_HARDENING.md`
- [ ] P1: AI Gateway automation handoff plan to AUTOMATION_SERVER | ID: ASDEV-AUTO-AI-GATEWAY-AUTOMATION-HANDOFF | Mode: docs-only | Priority: 1 | Blocked until issue #94 passes and owner approves rollout
- [ ] P1: PersianToolbox development freeze and revenue-mode handoff | ID: ASDEV-AUTO-PTB-DEV-FREEZE-REVENUE-HANDOFF | Mode: docs/business-ops | Priority: 2 | Awaiting owner approval
- [ ] Refactor ASDEV deploy scripts for mandatory live verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-ASDEV | Mode: docs-only/automation-script | Priority: 3
- [ ] Refactor AuditSystems deploy scripts for post-deploy live verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-AUDIT | Mode: docs-only/automation-script | Priority: 3
- [ ] Refactor Novax deploy docs/scripts for Worker + Telegram post-deploy verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-NOVAX | Mode: docs-only/automation-script | Priority: 3

## Gated pending
| Phrase | Theme |
|--------|--------|
| APPROVE_AUTOMATION_SERVER_REBOOT_DRILL | Controlled AUTOMATION_SERVER reboot-resilience test |
| APPROVE_CRITICAL_SITE_PUBLIC_EDGE | nginx/SSL/DNS + CWV |
| APPROVE_MONITORING_LIVE_TIMERS | live probes |
| APPROVE_CRITICAL_SITE_MIGRATION | DB |
| APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY | PersianToolbox public deploy/cutover |
| APPROVE_CRITICAL_SITE_ROLLBACK | rollback public production release |
| APPROVE_AI_GATEWAY_AUTOMATION_ROLLOUT | move local AI Gateway to AUTOMATION_SERVER timer/service |
| APPROVE_PUBLIC_AI_CHAT_PRODUCT | start a public-facing AI chat product |

## NEXT
1. AUTOMATION_SERVER sync discovers issue #94 prompt automatically.
2. OpenCode executes final reliability hardening on AUTOMATION_SERVER.
3. Reboot drill remains gated until explicit owner approval.
4. AI Gateway automation rollout remains disabled until issue #94 passes and owner approval is provided.
- [ ] CMD-4907715330 — Implement zero-copy ASDEV status watcher. Goal: user must not copy reports between ChatGPT and MiMo. VPS/Hermes runner should poll Issue #45 on schedule, track last processed comment id in durable state, parse ASDEV commands, post status only when state changes, and keep safe-mode rules active. Do not print secrets. Do not edit protected repos. Do not deploy production. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4908907999 — Build the ASDEV product growth roadmap. Coordinate agents through Issue #45. Deliver roadmap, backlog, validation gates, deployment plan for the existing server, rollback plan, and live-site audit plan. Keep protected repos unchanged. No secrets. No production deployment in this task. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911473383 — Operational Excellence Sprint. System is green, so start real post-launch work: synthetic monitoring, backup and restore drill, security header audit, performance budget, live UX audit, SEO basics, incident runbook, error log review, uptime evidence, and 7-day growth backlog. Create focused PRs/issues only. Do not expose credentials. Keep protected repos unchanged. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911786282 — PR #64 merged operational docs. Next safe step: convert the Operational Excellence docs into small tracked execution issues/PRs, prioritizing non-destructive checks only: monitoring evidence, backup/restore drill documentation, security header verification, performance budget measurement, live UX audit notes, SEO basics, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. Do not deploy production, do not expose credentials, do not touch PersianToolbox, and do not make destructive database/schema/billing changes. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4914107161 — Fix Telegram status bot now. Root cause: bot uses wrong repo names such as AliRezaSafaeiSystems and calls GitHub endpoints without the real owner/repo. Patch bot to use exact repo slugs: alirezasafaei-dev/alirezasafaeisystems and alirezasafaei-dev/auditsystems. Fix /status, /prs, /blockers, and /last. /last must fetch the latest Issue #45 comment, not the first page item. Add tests or a dry-run script for all commands. Restart the bot after validation. Then continue heavy ops work: monitoring checks, backup/restore drill, security headers, performance budget, live UX audit, SEO checks, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. You may plan, code, test, document, commit, push, open focused PRs, merge low-risk validated PRs, and restart the bot service. Do not expose credentials. Do not edit protected repos. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4907715330 — Implement zero-copy ASDEV status watcher. Goal: user must not copy reports between ChatGPT and MiMo. VPS/Hermes runner should poll Issue #45 on schedule, track last processed comment id in durable state, parse ASDEV commands, post status only when state changes, and keep safe-mode rules active. Do not print secrets. Do not edit protected repos. Do not deploy production. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4908907999 — Build the ASDEV product growth roadmap. Coordinate agents through Issue #45. Deliver roadmap, backlog, validation gates, deployment plan for the existing server, rollback plan, and live-site audit plan. Keep protected repos unchanged. No secrets. No production deployment in this task. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911473383 — Operational Excellence Sprint. System is green, so start real post-launch work: synthetic monitoring, backup and restore drill, security header audit, performance budget, live UX audit, SEO basics, incident runbook, error log review, uptime evidence, and 7-day growth backlog. Create focused PRs/issues only. Do not expose credentials. Keep protected repos unchanged. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911786282 — PR #64 merged operational docs. Next safe step: convert the Operational Excellence docs into small tracked execution issues/PRs, prioritizing non-destructive checks only: monitoring evidence, backup/restore drill documentation, security header verification, performance budget measurement, live UX audit notes, SEO basics, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. Do not deploy production, do not expose credentials, do not touch PersianToolbox, and do not make destructive database/schema/billing changes. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4914107161 — Fix Telegram status bot now. Root cause: bot uses wrong repo names such as AliRezaSafaeiSystems and calls GitHub endpoints without the real owner/repo. Patch bot to use exact repo slugs: alirezasafaei-dev/alirezasafaeisystems and alirezasafaei-dev/auditsystems. Fix /status, /prs, /blockers, and /last. /last must fetch the latest Issue #45 comment, not the first page item. Add tests or a dry-run script for all commands. Restart the bot after validation. Then continue heavy ops work: monitoring checks, backup/restore drill, security headers, performance budget, live UX audit, SEO checks, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. You may plan, code, test, document, commit, push, open focused PRs, merge low-risk validated PRs, and restart the bot service. Do not expose credentials. Do not edit protected repos. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4907715330 — Implement zero-copy ASDEV status watcher. Goal: user must not copy reports between ChatGPT and MiMo. VPS/Hermes runner should poll Issue #45 on schedule, track last processed comment id in durable state, parse ASDEV commands, post status only when state changes, and keep safe-mode rules active. Do not print secrets. Do not edit protected repos. Do not deploy production. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4908907999 — Build the ASDEV product growth roadmap. Coordinate agents through Issue #45. Deliver roadmap, backlog, validation gates, deployment plan for the existing server, rollback plan, and live-site audit plan. Keep protected repos unchanged. No secrets. No production deployment in this task. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911473383 — Operational Excellence Sprint. System is green, so start real post-launch work: synthetic monitoring, backup and restore drill, security header audit, performance budget, live UX audit, SEO basics, incident runbook, error log review, uptime evidence, and 7-day growth backlog. Create focused PRs/issues only. Do not expose credentials. Keep protected repos unchanged. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911786282 — PR #64 merged operational docs. Next safe step: convert the Operational Excellence docs into small tracked execution issues/PRs, prioritizing non-destructive checks only: monitoring evidence, backup/restore drill documentation, security header verification, performance budget measurement, live UX audit notes, SEO basics, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. Do not deploy production, do not expose credentials, do not touch PersianToolbox, and do not make destructive database/schema/billing changes. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4914107161 — Fix Telegram status bot now. Root cause: bot uses wrong repo names such as AliRezaSafaeiSystems and calls GitHub endpoints without the real owner/repo. Patch bot to use exact repo slugs: alirezasafaei-dev/alirezasafaeisystems and alirezasafaei-dev/auditsystems. Fix /status, /prs, /blockers, and /last. /last must fetch the latest Issue #45 comment, not the first page item. Add tests or a dry-run script for all commands. Restart the bot after validation. Then continue heavy ops work: monitoring checks, backup/restore drill, security headers, performance budget, live UX audit, SEO checks, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. You may plan, code, test, document, commit, push, open focused PRs, merge low-risk validated PRs, and restart the bot service. Do not expose credentials. Do not edit protected repos. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4907715330 — Implement zero-copy ASDEV status watcher. Goal: user must not copy reports between ChatGPT and MiMo. VPS/Hermes runner should poll Issue #45 on schedule, track last processed comment id in durable state, parse ASDEV commands, post status only when state changes, and keep safe-mode rules active. Do not print secrets. Do not edit protected repos. Do not deploy production. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4908907999 — Build the ASDEV product growth roadmap. Coordinate agents through Issue #45. Deliver roadmap, backlog, validation gates, deployment plan for the existing server, rollback plan, and live-site audit plan. Keep protected repos unchanged. No secrets. No production deployment in this task. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911473383 — Operational Excellence Sprint. System is green, so start real post-launch work: synthetic monitoring, backup and restore drill, security header audit, performance budget, live UX audit, SEO basics, incident runbook, error log review, uptime evidence, and 7-day growth backlog. Create focused PRs/issues only. Do not expose credentials. Keep protected repos unchanged. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911786282 — PR #64 merged operational docs. Next safe step: convert the Operational Excellence docs into small tracked execution issues/PRs, prioritizing non-destructive checks only: monitoring evidence, backup/restore drill documentation, security header verification, performance budget measurement, live UX audit notes, SEO basics, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. Do not deploy production, do not expose credentials, do not touch PersianToolbox, and do not make destructive database/schema/billing changes. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4914107161 — Fix Telegram status bot now. Root cause: bot uses wrong repo names such as AliRezaSafaeiSystems and calls GitHub endpoints without the real owner/repo. Patch bot to use exact repo slugs: alirezasafaei-dev/alirezasafaeisystems and alirezasafaei-dev/auditsystems. Fix /status, /prs, /blockers, and /last. /last must fetch the latest Issue #45 comment, not the first page item. Add tests or a dry-run script for all commands. Restart the bot after validation. Then continue heavy ops work: monitoring checks, backup/restore drill, security headers, performance budget, live UX audit, SEO checks, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. You may plan, code, test, document, commit, push, open focused PRs, merge low-risk validated PRs, and restart the bot service. Do not expose credentials. Do not edit protected repos. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4907715330 — Implement zero-copy ASDEV status watcher. Goal: user must not copy reports between ChatGPT and MiMo. VPS/Hermes runner should poll Issue #45 on schedule, track last processed comment id in durable state, parse ASDEV commands, post status only when state changes, and keep safe-mode rules active. Do not print secrets. Do not edit protected repos. Do not deploy production. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4908907999 — Build the ASDEV product growth roadmap. Coordinate agents through Issue #45. Deliver roadmap, backlog, validation gates, deployment plan for the existing server, rollback plan, and live-site audit plan. Keep protected repos unchanged. No secrets. No production deployment in this task. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911473383 — Operational Excellence Sprint. System is green, so start real post-launch work: synthetic monitoring, backup and restore drill, security header audit, performance budget, live UX audit, SEO basics, incident runbook, error log review, uptime evidence, and 7-day growth backlog. Create focused PRs/issues only. Do not expose credentials. Keep protected repos unchanged. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911786282 — PR #64 merged operational docs. Next safe step: convert the Operational Excellence docs into small tracked execution issues/PRs, prioritizing non-destructive checks only: monitoring evidence, backup/restore drill documentation, security header verification, performance budget measurement, live UX audit notes, SEO basics, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. Do not deploy production, do not expose credentials, do not touch PersianToolbox, and do not make destructive database/schema/billing changes. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4914107161 — Fix Telegram status bot now. Root cause: bot uses wrong repo names such as AliRezaSafaeiSystems and calls GitHub endpoints without the real owner/repo. Patch bot to use exact repo slugs: alirezasafaei-dev/alirezasafaeisystems and alirezasafaei-dev/auditsystems. Fix /status, /prs, /blockers, and /last. /last must fetch the latest Issue #45 comment, not the first page item. Add tests or a dry-run script for all commands. Restart the bot after validation. Then continue heavy ops work: monitoring checks, backup/restore drill, security headers, performance budget, live UX audit, SEO checks, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. You may plan, code, test, document, commit, push, open focused PRs, merge low-risk validated PRs, and restart the bot service. Do not expose credentials. Do not edit protected repos. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4907715330 — Implement zero-copy ASDEV status watcher. Goal: user must not copy reports between ChatGPT and MiMo. VPS/Hermes runner should poll Issue #45 on schedule, track last processed comment id in durable state, parse ASDEV commands, post status only when state changes, and keep safe-mode rules active. Do not print secrets. Do not edit protected repos. Do not deploy production. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4908907999 — Build the ASDEV product growth roadmap. Coordinate agents through Issue #45. Deliver roadmap, backlog, validation gates, deployment plan for the existing server, rollback plan, and live-site audit plan. Keep protected repos unchanged. No secrets. No production deployment in this task. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911473383 — Operational Excellence Sprint. System is green, so start real post-launch work: synthetic monitoring, backup and restore drill, security header audit, performance budget, live UX audit, SEO basics, incident runbook, error log review, uptime evidence, and 7-day growth backlog. Create focused PRs/issues only. Do not expose credentials. Keep protected repos unchanged. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4911786282 — PR #64 merged operational docs. Next safe step: convert the Operational Excellence docs into small tracked execution issues/PRs, prioritizing non-destructive checks only: monitoring evidence, backup/restore drill documentation, security header verification, performance budget measurement, live UX audit notes, SEO basics, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. Do not deploy production, do not expose credentials, do not touch PersianToolbox, and do not make destructive database/schema/billing changes. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
- [ ] CMD-4914107161 — Fix Telegram status bot now. Root cause: bot uses wrong repo names such as AliRezaSafaeiSystems and calls GitHub endpoints without the real owner/repo. Patch bot to use exact repo slugs: alirezasafaei-dev/alirezasafaeisystems and alirezasafaei-dev/auditsystems. Fix /status, /prs, /blockers, and /last. /last must fetch the latest Issue #45 comment, not the first page item. Add tests or a dry-run script for all commands. Restart the bot after validation. Then continue heavy ops work: monitoring checks, backup/restore drill, security headers, performance budget, live UX audit, SEO checks, incident runbook, error-log review, uptime evidence, and 7-day growth backlog. You may plan, code, test, document, commit, push, open focused PRs, merge low-risk validated PRs, and restart the bot service. Do not expose credentials. Do not edit protected repos. No destructive database work. | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps
