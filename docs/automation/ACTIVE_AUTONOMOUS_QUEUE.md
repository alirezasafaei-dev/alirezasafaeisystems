# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-10T05:30:00Z  
**Status:** AUTOMATION_HOST FULL PASS · 10min LOOP · TCP ACTIVE · MCP LIVE · POST-DEPLOY LIVE VERIFICATION POLICY ACTIVE

## Runtime
- Host: `asdev` (local AUTOMATION_HOST)
- Hermes: active + TELEGRAM_PROXY socks5h://127.0.0.1:10808
- OpenClaw: active, Telegram disabled (bot conflict)
- Timers: asdev-agent-loop 10min · health 1h
- Hermes cron: asdev-control-plane-loop every 10min

## Mandatory policy
- `docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md`
- Deployment is not done until the real live public site/service has passed real browser verification and operational checks.
- Agents must refactor deploy scripts so final success cannot be printed before live verification passes.

## Safe continuous
- loop-once safe-auto drain
- multi-agent mimo/opencode under Grok
- product quality pre-deploy

## Completed safe cycles
- [x] MCP health monitor report | ID: ASDEV-AUTO-MCP-HEALTH | Mode: read-only | Priority: 3
- [x] Control-plane queue integrity check | ID: ASDEV-AUTO-QUEUE-INTEGRITY | Mode: automation-script | Priority: 3
- [x] Agent memory freshness check | ID: ASDEV-AUTO-MEMORY-FRESH | Mode: docs-only | Priority: 3
- [x] MCP recurring health verify | ID: ASDEV-AUTO-MCP-SSE | Mode: read-only | Priority: 4
- [x] OpenClaw gateway diagnostic only | ID: ASDEV-AUTO-OPENCLAW-DIAG | Mode: read-only | Priority: 5

## Safe next cycles
- [ ] Refactor ASDEV deploy scripts for mandatory live verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-ASDEV | Mode: docs-only/automation-script | Priority: 1
- [ ] Refactor PersianToolbox deploy scripts for real browser post-deploy checks | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-PTB | Mode: docs-only/automation-script | Priority: 1
- [ ] Refactor AuditSystems deploy scripts for post-deploy live verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-AUDIT | Mode: docs-only/automation-script | Priority: 1
- [ ] Refactor Novax deploy docs/scripts for Worker + Telegram post-deploy verification | ID: ASDEV-AUTO-DEPLOY-LIVE-VERIFY-NOVAX | Mode: docs-only/automation-script | Priority: 2
- [ ] Add live-verification report template and wrapper conventions to deployment docs | ID: ASDEV-AUTO-LIVE-VERIFY-TEMPLATE | Mode: docs-only | Priority: 2
- [ ] PersianToolbox post-batch independent verification | ID: ASDEV-AUTO-PTB-VERIFY-20260709 | Mode: read-only/docs-only | Priority: 2
- [ ] PersianToolbox deploy readiness evidence report | ID: ASDEV-AUTO-PTB-DEPLOY-READINESS-20260709 | Mode: docs-only | Priority: 2
- [ ] Compare PersianToolbox GitHub HEAD vs public live release | ID: ASDEV-AUTO-PTB-DRIFT-20260709 | Mode: read-only | Priority: 3
- [ ] Review MiMo testimonial/trust changes for non-fabrication risk | ID: ASDEV-AUTO-PTB-TRUST-REVIEW-20260709 | Mode: docs-only/read-only | Priority: 3
- [ ] Re-check Hermes/OpenClaw service split after duplicate bot removal | ID: ASDEV-AUTO-HERMES-OPENCLAW-VERIFY-20260709 | Mode: read-only | Priority: 4

## Gated pending
| Phrase | Theme |
|--------|--------|
| APPROVE_CRITICAL_SITE_PUBLIC_EDGE | nginx/SSL/DNS + CWV |
| APPROVE_MONITORING_LIVE_TIMERS | live probes |
| APPROVE_CRITICAL_SITE_MIGRATION | DB |
| APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY | PersianToolbox public deploy/cutover |
| APPROVE_CRITICAL_SITE_ROLLBACK | rollback public production release |

## NEXT
Automation agents must read the post-deploy live verification policy and refactor deployment scripts/docs so no deployment can be called successful without real live browser verification. Deploy and rollback remain gated; no production mutation without exact approval phrase.
