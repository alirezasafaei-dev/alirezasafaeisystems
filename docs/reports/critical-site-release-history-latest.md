# CRITICAL_SITE Release History Snapshot

**Date:** 2026-07-08T22:50:00Z  
**Host:** IRAN_PROD  
**Tool:** `asdev-release-history.sh` / `asdev-rollback-rehearse.sh`

## History

| Release | Role | Port | Commit |
|---------|------|------|--------|
| `20260708T221124Z-fcc7192` | **CURRENT** production | 3100 | `fcc7192af26a…` |

shown=1

## Rollback rehearse (dry-run)

```
previous_release_field=EMPTY
second_newest_release=NONE
RESULT=NO_ROLLBACK_TARGET (first deploy posture)
RECOVERY=redeploy same pin with production phrase OR emergency stop pid
```

## Implication

Highest-value **gated** improvement for rollback maturity: second production release under  
`APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` (not executed).

Safe preparation remains complete.
