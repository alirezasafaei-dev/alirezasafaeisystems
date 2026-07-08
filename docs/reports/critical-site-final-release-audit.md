# CRITICAL_SITE Final Release Candidate Audit

**Date:** 2026-07-08T21:40:00Z  
**Role:** ASDEV Release Manager  
**Production mutation:** **none**  

---

## Decision summary

| Field | Value |
|-------|-------|
| Engineering RC status | **READY_FOR_PRODUCTION_APPROVAL** |
| Owner pre-steps | 1) Merge PR #72 to main  2) Phrase below |
| Staging | LIVE_OK (`20260708T210149Z-fcc7192`, ready/health 200) |
| Production | untouched (`prod_current=no`) |
| AUTOMATION_HOST | DEGRADED_NON_BLOCKING |
| Product pin | `fcc7192af26a5713e31d4ec078365f9507c8108a` |

```
READY_FOR_PRODUCTION_APPROVAL

NEXT_GATE:
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

---

## 1) Release candidate validation

| Item | Result | Notes |
|------|--------|-------|
| GitHub main clean | PASS | main at `eaddee4` |
| RC on PR #72 | PASS | mergeable; **not yet on main** |
| OWNER_PC path `/home/dev13/ASDEV` | PASS | symlink to mother repo |
| Working tree for audit batch | clean after commit |
| Secrets tracked | PASS | no `.env`/keys tracked; example env only |
| Registry valid | PASS | 21 cols; PT 3100/3200 |
| Staging commit identifiable | PASS | `fcc7192…` in release.meta |
| Prod uses same product pin | PASS | strategy documented in `critical-site-release-pin.md` |
| Platform engine on main | **OWNER STEP** | merge PR #72 first |

---

## 2) Deploy engine final review

| Requirement | Result |
|-------------|--------|
| Immutable releases under `releases/` | PASS |
| release.meta | PASS |
| current symlink cutover only | PASS |
| previous-release pointer | PASS |
| Post-activation healthcheck | PASS (`check-healthcheck-order`) |
| Failed health → rollback symlink | PASS |
| No eval in asdev-deploy path | PASS |
| Dangerous patterns | 0 |
| Port env resolve | PASS (3100 prod / 3200 staging) |
| Port guard if occupied | PASS |
| Migration block | PASS |
| Legacy default port 3000 | **removed** (refuses missing port) |

Dry-run production cutover simulation: **PASS** (all stages).

---

## 3) Port and runtime isolation

| Env | Registry | Live IRAN_PROD |
|-----|----------|----------------|
| production | **3100** | not running; port free |
| staging | **3200** | still **legacy :3000** listening |

| Question | Answer |
|----------|--------|
| Blocks production on 3100? | **No** (different port) |
| Remediation | Optional: rebind staging to 3200 with staging phrase |
| nginx templates | Documented; **not applied** |

---

## 4) Cutover simulation (dry-run only)

| Stage | Result |
|-------|--------|
| Preflight production | PASS (warnings: local missing /srv paths) |
| Release creation plan | PASS |
| Activation plan (symlink) | PASS |
| Healthcheck plan (:3100) | PASS |
| Failure → rollback path | PASS (engine code path) |
| Live activation | **NOT EXECUTED** (forbidden) |

---

## 5) Rollback confidence

| Item | Result |
|------|--------|
| Rollback command deterministic | PASS |
| Health after rollback | PASS (scripted) |
| previous release exists (prod) | **N/A** — first prod; no prior release |
| Operator docs | PASS — `docs/ops/rollback-plan.md` |
| Staging rollback possible | PASS (staging has current release) |

---

## 6) AUTOMATION_HOST

**DEGRADED_NON_BLOCKING**

- Tools OK; deploy scripts OK; SSH orchestration proven  
- PM2 idle expected; no GHA runner (optional)  
- Not blocking production via SSH executor path  

---

## 7) Documentation pack

| Doc | Status |
|------|--------|
| `docs/ops/production-readiness-gate.md` | present |
| `docs/ops/production-execution-plan.md` | present |
| `docs/ops/rollback-plan.md` | **created** |
| `docs/ops/INCIDENT_RUNBOOK.md` | present (incident-runbook) |
| `docs/ops/critical-site-release-pin.md` | **created** |
| `docs/reports/critical-site-final-release-audit.md` | this file |

---

## Exact production steps (after phrase)

1. Merge PR #72 → main; sync IRAN platform checkout  
2. Confirm product pin `fcc7192…` (or re-stage newer SHA)  
3. Confirm port 3100 free; staging may remain on 3000  
4. `asdev-preflight … production` (live check ok)  
5. `asdev-deploy … --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`  
6. Verify `http://127.0.0.1:3100/api/ready` → 200  
7. Wire nginx only if public go-live required (separate approval if reload)  
8. Monitor  

## Exact rollback steps

See `docs/ops/rollback-plan.md`. First prod has no previous release until second deploy.

---

## Remaining risks (accepted / residual)

1. **PR #72 not on main yet** — owner merge required  
2. **Staging legacy :3000** — non-blocking for 3100 prod  
3. **First prod rollback limited** — no previous prod release  
4. **Nginx/public edge not configured** — internal 3100 go-live only until edge  
5. **CI GitHub infra red** — local router green; non-blocking for engine  
6. **Shared env secrets** — verify on host at execute time (not in git)  

---

## Intentionally not executed

- Production deploy / symlink switch  
- nginx reload  
- DNS/SSL/firewall  
- DB migration  
- Staging live rebind  
- Release deletion  

---

## Final gate strings

```
READY_FOR_PRODUCTION_APPROVAL

NEXT_GATE:
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

Owner checklist before pasting phrase:

1. Merge PR #72 to main  
2. Accept residual risks above  
3. Be ready to run production steps on IRAN_PROD  
