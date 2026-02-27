# On-Call and Escalation Ownership

## Purpose
Define who responds to production incidents and how escalation works for `alirezasafaeisystems`.

## Roles
- Service: `alirezasafaeisystems`
- Primary on-call: `platform-owner`
- Backup on-call: `devops-backup`
- Release approver: `platform-owner`
- Incident commander (P1/P0): `incident-commander`

## Alert Sources
- GitHub Action: `SLO Monitor` (`.github/workflows/slo-monitor.yml`)
- Health endpoint: `GET /api/ready`
- PM2 process health (`my-portfolio-production`, `my-portfolio-staging`)

## Escalation Policy
1. P2 issue (degraded, no outage): primary on-call responds within 4h.
2. P1 issue (partial outage): primary responds within 30m, backup auto-escalated at +15m.
3. P0 issue (full outage/security risk): immediate escalation to incident commander and release approver.

## Communication Channels
- Primary channel: `telegram:@asdev_ops_alerts`
- Backup channel: `email:ops-backup@alirezasafaeisystems.ir`
- Incident log location: `docs/runtime/Incidents/`

## Approval Gates
- Production deploy requires:
- quality gates pass (`verify`, smoke, security checks)
- active on-call assignment for deployment window
- rollback operator explicitly assigned

## Review Cadence
- Weekly: check alert noise and unresolved incidents.
- Monthly: run one rollback drill and attach incident note.
