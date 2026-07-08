# Approval Gates — Minimal Set

**Last Updated:** 2026-07-08  
**Policy:** Gates only for irreversible / public / data-risk actions.

---

## Gated (must have exact phrase in session)

| Phrase | Unlocks |
|--------|---------|
| `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` | nginx reload, public SSL install, DNS cutover for CRITICAL_SITE |
| `APPROVE_CRITICAL_SITE_MIGRATION` | production DB migrations |
| `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` | production app-layer deploy / redeploy |
| `APPROVE_PHASE_2_STAGING_DEPLOY` | staging deploy mutation |
| `APPROVE_MONITORING_LIVE_TIMERS` | install host cron/systemd **probe timers** (not meta-backup already present) |
| `APPROVE_CRITICAL_SITE_STAGING_REBIND` | stop/rebind staging ports live |
| `APPROVE_RELEASE_DELETE` | hard-delete releases |
| Destructive docker/pm2 cleanup | explicit owner OK (no fixed phrase yet) |

---

## Not gated (must continue autonomously)

- Docs, governance, memory, roadmaps  
- Agent registry, queue, control plane tools  
- Deploy engine improvements + dry-run tests  
- Rollback **rehearsal** dry-run  
- Observability **foundation** (scripts/docs/dashboards specs) without live install  
- Project standardization (`project.yaml`, templates)  
- Security audits and secret scanning (local)  
- Performance analysis without production change  
- Preparing nginx templates (no reload)  

---

## Informal language

“go ahead”, “ship it”, “approved” alone are **insufficient** for gated rows above.
