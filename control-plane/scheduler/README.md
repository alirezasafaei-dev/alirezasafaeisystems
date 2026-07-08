# Scheduler examples

**Do not install live timers without** `APPROVE_MONITORING_LIVE_TIMERS`.

Examples only:

```cron
# Daily automation-host health snapshot (example — not installed)
# 0 */6 * * * ASDEV_ROOT=/home/dev13/ASDEV bash /home/dev13/ASDEV/scripts/ops/automation-health-check.sh
```

IRAN meta backup cron is separate (already on IRAN_PROD; not modified here).
