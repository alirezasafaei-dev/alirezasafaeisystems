# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-10T08:10:00Z  
**Status:** ENVIRONMENT ROLES POLICY ACTIVE · GITHUB SYNC SERVICE CREATED · AUTOMATION_SERVER SYNC ROLLOUT REQUIRED

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
- Deployment is not done until the real live public site/service has passed real browser verification and operational checks.
- Prompt/policy/queue files committed to GitHub must become discoverable on `AUTOMATION_SERVER` without manual copy-paste.

## Immediate incident note
- MiMo claims PersianToolbox was fixed by copying missing Next.js JS chunks into standalone build.
- GitHub contains the JS chunk copy fix and a curl-based post-deploy verification script.
- The current verification script is useful but not sufficient for the mandatory policy because it is not real-browser verification and does not prove navbar/blog/tool interactions.

## Safe continuous
- GitHub sync every 5 minutes after `asdev-github-sync.timer` rollout.
- loop-once safe-auto drain.
- multi-agent MiMo/OpenCode under explicit environment naming.
- product quality pre-deploy.

## Completed safe cycles
- [x] MCP health monitor report | ID: ASDEV-AUTO-MCP-HEALTH | Mode: read-only | Priority: 3
- [x] Control-plane queue integrity check | ID: ASDEV-AUTO-QUEUE-INTEGRITY | Mode: automation-script | Priority: 3
- [x] Agent memory freshness check | ID: ASDEV-AUTO-MEMORY-FRESH | Mode: docs-only | Priority: 3
- [x] MCP recurring health verify | ID: ASDEV-AUTO-MCP-SSE | Mode: read-only | Priority: 4
- [x] OpenClaw gateway diagnostic only | ID: ASDEV-AUTO-OPENCLAW-DIAG | Mode: read-only | Priority: 5

## Safe next cycles
- [x] Install/enable  on `AUTOMATION_SERVER` | ID: ASDEV-AUTO-GITHUB-SYNC-TIMER-INSTALL | Mode: automation-script | Priority: 0 | Command: `ASDEV_ENVIRONMENT=AUTOMATION_SERVER bash scripts/control-plane/install-github-sync-service.sh`
- [x] Verify GitHub sync pulls new prompts without manual copy | ID: ASDEV-AUTO-GITHUB-SYNC-PROMPT-DISCOVERY | Mode: read-only/automation-script | Priority: 0
- [x] Fix stale Telegram/OpenClaw branch/issue status labels using environment roles policy | ID: ASDEV-AUTO-TELEGRAM-STALE-STATUS-FIX | Mode: automation-script | Priority: 1
- [x] URGENT: Verify PersianToolbox MiMo hotfix with real browsers | ID: ASDEV-AUTO-PTB-MIMO-HOTFIX-BROWSER-VERIFY | Mode: read-only/automation-script | Priority: 1 | Prompt: `prompts/opencode/VERIFY_PERSIANTOOLBOX_MIMO_HOTFIX.md`
- [x] Upgrade PersianToolbox post-deploy verification from curl-only to Playwright-backed live verification | ID: ASDEV-AUTO-PTB-LIVE-VERIFY-PLAYWRIGHT | Mode: automation-script | Priority: 1
- [x] Integrate PersianToolbox live verification into deploy-blue-green.sh final success gate | ID: ASDEV-AUTO-PTB-DEPLOY-SUCCESS-GATE | Mode: automation-script | Priority: 1
- [x] Refactor ASDEV deploy scripts for mandatory live verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-ASDEV | Mode: docs-only/automation-script | Priority: 2
- [ ] Refactor AuditSystems deploy scripts for post-deploy live verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-AUDIT | Mode: docs-only/automation-script | Priority: 2
- [ ] Refactor Novax deploy docs/scripts for Worker + Telegram post-deploy verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-NOVAX | Mode: docs-only/automation-script | Priority: 2
- [ ] Add live-verification report template and wrapper conventions to deployment docs | ID: ASDEV-AUTO-LIVE-VERIFY-TEMPLATE | Mode: docs-only | Priority: 2
- [ ] Compare PersianToolbox GitHub HEAD vs public live release | ID: ASDEV-AUTO-PTB-DRIFT-20260709 | Mode: read-only | Priority: 3
- [ ] Review MiMo testimonial/trust changes for non-fabrication risk | ID: ASDEV-AUTO-PTB-TRUST-REVIEW-20260709 | Mode: docs-only/read-only | Priority: 3
- [x] Re-check Hermes/OpenClaw service split after duplicate bot removal | ID: ASDEV-AUTO-HERMES-OPENCLAW-VERIFY-20260709 | Mode: read-only | Priority: 4

## Gated pending
| Phrase | Theme |
|--------|--------|
| APPROVE_CRITICAL_SITE_PUBLIC_EDGE | nginx/SSL/DNS + CWV |
| APPROVE_MONITORING_LIVE_TIMERS | live probes |
| APPROVE_CRITICAL_SITE_MIGRATION | DB |
| APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY | PersianToolbox public deploy/cutover |
| APPROVE_CRITICAL_SITE_ROLLBACK | rollback public production release |

## NEXT
First install and verify the GitHub sync timer on `AUTOMATION_SERVER`. Then verify PersianToolbox with real browsers and upgrade deploy verification from curl-only to Playwright-backed. Deploy and rollback remain gated; no production mutation without exact approval phrase.
