# Alert Strategy

## Severity

| Sev | Example | Response |
|-----|---------|----------|
| SEV1 | CRITICAL_SITE ready fail on IRAN loopback | page + incident runbook |
| SEV2 | Public edge down but local app up | edge path only |
| SEV3 | Backup stale > 36h | same-day fix |
| SEV4 | PM2 idle / no runner | ignore or backlog |

## Channels (policy)

- Prefer existing Telegram/webhook if configured (no secrets in git)  
- See `docs/ops/alerting-policy.md`  

## Do not alert

- Desktop Chrome CPU on AUTOMATION_HOST  
- GHA infra flakes without product impact  
