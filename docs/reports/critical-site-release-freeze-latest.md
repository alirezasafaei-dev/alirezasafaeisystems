# CRITICAL_SITE Release Candidate Freeze

**Date:** 2026-07-08T21:44:00Z  
**Status:** **FROZEN**  
**Production mutation:** **none**

---

## Platform commit (frozen)

| Field | Value |
|-------|-------|
| Repo | `alirezasafaei-dev/alirezasafaeisystems` |
| Branch | `main` |
| Full SHA | `5aff1dfed17dcf0672b3022564b321660b297580` |
| Short | `5aff1df` |
| How arrived | Merge PR #72 (admin merge; GHA infra red, local validation green) |
| OWNER_PC | synced ff-only to `origin/main` @ `5aff1df` |
| IRAN_PROD platform checkout | `/home/asdev/asdev-platform` synced (scripts/deploy, scripts/ops, deploy/); pin file written |

---

## Product commit (frozen)

| Field | Value |
|-------|-------|
| Repo | `alirezasafaei-dev/persiantoolbox` |
| Full SHA | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Short | `fcc7192` |
| Staging release | `20260708T210149Z-fcc7192` |
| Staging health | ready **200**, health **200** (re-verified at freeze) |
| Rule | Production **must** use this SHA unless new SHA re-staged |

---

## Reproducible deployment equation

```
ASDEV platform 5aff1df
+
CRITICAL_SITE product fcc7192
=
production release candidate
```

---

## Staging evidence

| Check | Result |
|-------|--------|
| current | `20260708T210149Z-fcc7192` |
| product commit in meta | `fcc7192…` matches pin |
| ready/health | 200/200 |
| prod_current | **no** |
| Live listen | legacy **:3000** (registry staging target 3200 — residual) |

---

## Deploy method (for next gate)

1. On IRAN_PROD: platform at `/home/asdev/asdev-platform` (synced)  
2. Product source pin `fcc7192` (clone/checkout if needed)  
3. Build on host (`NODE_OPTIONS=--max-old-space-size=3072`, HUSKY=0)  
4. `asdev-deploy.sh --site persiantoolbox --environment production --commit fcc7192… --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`  
5. Runtime port **3100**  
6. Health `http://127.0.0.1:3100/api/ready`  

Docs: `docs/ops/production-execution-plan.md`

---

## Rollback method

- Symlink swap via `asdev-rollback.sh`  
- First prod: **no previous release** until second deploy  
- Doc: `docs/ops/rollback-plan.md`

---

## Remaining risks

| Risk | Severity | Notes |
|------|----------|-------|
| Staging still on :3000 not :3200 | Low for prod | Does not occupy 3100 |
| First prod rollback limited | Medium | Accepted for first cutover |
| Nginx/public edge not wired | Medium | Internal 3100 until edge approved |
| Shared secrets on host | Medium | Verify at execute time |
| GHA CI infra red | Low | Local validation used for merge |

---

## Required owner action

```
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

Only remaining **execution** gate. Freeze complete.

---

## Intentionally not executed

- Production deploy / symlink  
- nginx reload  
- DNS/SSL  
- migration  
- Staging rebind  

---

## Final strings

```
READY_FOR_PRODUCTION_FREEZE

NEXT_GATE:
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
