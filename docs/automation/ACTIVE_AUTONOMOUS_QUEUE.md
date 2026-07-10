# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-10T14:45:00Z  
**Status:** ENVIRONMENT ROLES POLICY ACTIVE · GITHUB SYNC ACTIVE · PERSIANTOOLBOX STABILIZATION BLOCKED BY OWNER CONFIG · LOCAL AI GATEWAY MVP NEXT

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
- PersianToolbox stabilization: 4/5 P0/P1 items DONE. Remaining: ZARINPAL_MERCHANT_ID owner action + owner freeze acceptance.
- Payment fixes deployed in GitHub: Toman→IRR conversion, auth gate, error handling, loading state, health indicator.
- Admin dashboard: live API calls replacing hardcoded stubs.
- SSR audit: all main pages + 99 tool pages server-rendered. Performance acceptable.
- Since PersianToolbox remaining work is owner/production-config gated, use idle local OpenCode capacity for the ASDEV AI Gateway local-first MVP.
- AI Gateway is internal infrastructure first, not a public unlimited free ChatGPT clone.

## Safe continuous
- GitHub sync every 5 minutes/10 minutes according to installed timer policy.
- loop-once safe-auto drain.
- multi-agent MiMo/OpenCode under explicit environment naming.
- product quality pre-deploy.

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

## Safe next cycles
- [ ] P0: ASDEV AI Gateway local-first MVP with OpenCode | ID: ASDEV-AUTO-AI-GATEWAY-LOCAL-MVP | Mode: LOCAL_PC/opencode/docs+scripts | Priority: 0 | Prompt: `prompts/opencode/LOCAL_AI_GATEWAY_MVP.md`
- [ ] P0: AI provider health and registry verification on LOCAL_PC | ID: ASDEV-AUTO-AI-GATEWAY-PROVIDER-HEALTH | Mode: LOCAL_PC/read-only/script | Priority: 0 | Command: `ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/provider-health.sh`
- [ ] P1: AI task router dry-run sample tasks | ID: ASDEV-AUTO-AI-GATEWAY-TASK-ROUTER | Mode: LOCAL_PC/script | Priority: 1 | Command: `ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh provider-health prompts/ai-router/sample-provider-health.md`
- [ ] P1: AI Gateway automation handoff plan to AUTOMATION_SERVER | ID: ASDEV-AUTO-AI-GATEWAY-AUTOMATION-HANDOFF | Mode: docs-only | Priority: 2 | Blocked until local MVP passes
- [ ] P1: PersianToolbox development freeze and revenue-mode handoff | ID: ASDEV-AUTO-PTB-DEV-FREEZE-REVENUE-HANDOFF | Mode: docs/business-ops | Priority: 2 | Awaiting: ZARINPAL_MERCHANT_ID + owner approval
- [ ] Refactor ASDEV deploy scripts for mandatory live verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-ASDEV | Mode: docs-only/automation-script | Priority: 3
- [ ] Refactor AuditSystems deploy scripts for post-deploy live verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-AUDIT | Mode: docs-only/automation-script | Priority: 3
- [ ] Refactor Novax deploy docs/scripts for Worker + Telegram post-deploy verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-NOVAX | Mode: docs-only/automation-script | Priority: 3

## Gated pending
| Phrase | Theme |
|--------|--------|
| APPROVE_CRITICAL_SITE_PUBLIC_EDGE | nginx/SSL/DNS + CWV |
| APPROVE_MONITORING_LIVE_TIMERS | live probes |
| APPROVE_CRITICAL_SITE_MIGRATION | DB |
| APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY | PersianToolbox public deploy/cutover |
| APPROVE_CRITICAL_SITE_ROLLBACK | rollback public production release |
| APPROVE_AI_GATEWAY_AUTOMATION_ROLLOUT | move local AI Gateway to AUTOMATION_SERVER timer/service |
| APPROVE_PUBLIC_AI_CHAT_PRODUCT | start a public-facing AI chat product |

## NEXT
Run `prompts/opencode/LOCAL_AI_GATEWAY_MVP.md` from `LOCAL_PC` through OpenCode. Keep it local-first. Do not deploy. Do not expose free/personal provider access to public users. Automation handoff only after local MVP evidence exists.
