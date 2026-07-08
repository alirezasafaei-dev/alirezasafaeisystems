# Alerting Policy — ASDEV

**Last Updated:** 2026-07-08  
**Status:** Policy only (no live alert channels changed by this document)

---

## Principles

1. **Signal over noise** — alert on user impact or deploy readiness, not every warning.
2. **No secrets in alerts** — never include tokens, env dumps, raw IPs, or private keys.
3. **Aliases only** — OWNER_PC, AUTOMATION_HOST, IRAN_PROD, CRITICAL_SITE.
4. **GitHub is not a pager** — do not spam issues/PRs with check output.

---

## Severity levels

| Level | Meaning | Response |
|-------|---------|----------|
| **P0** | CRITICAL_SITE down or data-loss risk | Immediate owner notify + incident runbook |
| **P1** | AUTOMATION_HOST not ready for approved deploy | Repair host; block staging/prod deploy |
| **P2** | Disk/backup freshness degraded | Plan fix within 24h |
| **P3** | Optional tooling missing (e.g. self-hosted runner) | Track in queue; non-blocking |

---

## What alerts (when live timers approved)

| Signal | Severity | Source script |
|--------|----------|---------------|
| CRITICAL_SITE HTTP non-2xx after retries | P0 | `check-critical-site-http.sh` |
| AUTOMATION_HOST `NOT_READY` / `DEGRADED_BLOCKING` | P1 | `check-automation-host-readiness.sh` |
| Disk ≥ 90% | P1 | `check-disk-local.sh` |
| Disk ≥ 80% | P2 | `check-disk-local.sh` |
| Backup older than max age | P2 | `check-backup-freshness.sh` |

---

## What does not alert

- Single CI workflow failure while classified as GitHub Actions infrastructure issue
- Empty PM2 when no ASDEV ecosystem is configured
- Legacy exited Docker containers unrelated to ASDEV
- Dry-run / check-mode script output
- Docs-only PR noise

---

## Channels (planned)

| Channel | Use |
|---------|-----|
| Telegram (existing bot path) | P0/P1 only when live timers approved |
| Local report files under `docs/reports/` | All severities for audit trail |
| GitHub Issue #45 command bus | Summary only, max once per cycle |

---

## Approval gate for live alerting

Enabling cron/systemd/webhook delivery requires:

`APPROVE_MONITORING_LIVE_TIMERS`

Until then: run scripts manually or in approved autonomous loops only.
