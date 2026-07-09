# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-09T15:25:00Z  
**Status:** AUTOMATION_HOST FULL PASS · 10min LOOP · TCP ACTIVE · MCP LIVE

## Runtime
- Host: `asdev` (local AUTOMATION_HOST)
- Hermes: active + TELEGRAM_PROXY socks5h://127.0.0.1:10808
- OpenClaw: active, Telegram disabled (bot conflict)
- Timers: asdev-agent-loop 10min · health 1h
- Hermes cron: asdev-control-plane-loop every 10min

## Safe continuous
- loop-once safe-auto drain
- multi-agent mimo/opencode under Grok
- product quality pre-deploy

## Safe next cycles
- [ ] MCP health monitor report | ID: ASDEV-AUTO-MCP-HEALTH | Mode: read-only | Priority: 3
- [ ] Control-plane queue integrity check | ID: ASDEV-AUTO-QUEUE-INTEGRITY | Mode: automation-script | Priority: 3
- [ ] Agent memory freshness check | ID: ASDEV-AUTO-MEMORY-FRESH | Mode: docs-only | Priority: 3
- [ ] MCP recurring health verify | ID: ASDEV-AUTO-MCP-SSE | Mode: read-only | Priority: 4
- [ ] OpenClaw gateway diagnostic only | ID: ASDEV-AUTO-OPENCLAW-DIAG | Mode: read-only | Priority: 5

## Gated pending
| Phrase | Theme |
|--------|--------|
| APPROVE_CRITICAL_SITE_PUBLIC_EDGE | nginx/SSL/DNS + CWV |
| APPROVE_MONITORING_LIVE_TIMERS | live probes |
| APPROVE_CRITICAL_SITE_MIGRATION | DB |
| APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY | second release / cutover |

## NEXT
Continue multi-agent product quality; deploy last; no gated execution without phrase.
