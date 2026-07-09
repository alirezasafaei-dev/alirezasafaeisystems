# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-09T01:20:00Z  
**Status:** AUTOMATION_HOST FULL PASS · TIMERS ON · TELEGRAM VIA PROXY · GATED REMAIN  

## Runtime
- Host: `asdev` (local AUTOMATION_HOST)
- Hermes: active + TELEGRAM_PROXY socks5h://127.0.0.1:10808
- OpenClaw: active, Telegram disabled (bot conflict)
- Timers: asdev-agent-loop 30m · health 1h
- Hermes cron: asdev-control-plane-loop every 30m

## Safe continuous
- loop-once safe-auto drain
- multi-agent mimo/opencode under Grok
- product quality pre-deploy

## Gated pending
| Phrase | Theme |
|--------|--------|
| APPROVE_CRITICAL_SITE_PUBLIC_EDGE | nginx/SSL/DNS + CWV |
| APPROVE_MONITORING_LIVE_TIMERS | live probes |
| APPROVE_CRITICAL_SITE_MIGRATION | DB |
| APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY | second release / cutover |

## NEXT
Continue multi-agent product quality; deploy last; no gated execution without phrase.
