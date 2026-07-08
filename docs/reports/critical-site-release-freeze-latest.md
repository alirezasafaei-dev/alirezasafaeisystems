# CRITICAL_SITE Release Candidate Freeze

**Date:** 2026-07-08T21:45:00Z  
**Status:** **FROZEN**  
**Production mutation:** **none**

---

## Platform commit (frozen)

| Field | Value |
|-------|-------|
| Repo | `alirezasafaei-dev/alirezasafaeisystems` |
| Branch | `main` |
| Full SHA | `192d8d5f464dfdc56fa2d7ae611965430d930fae` |
| Short | `192d8d5` |
| How arrived | PR #72 merged (`5aff1df`) + freeze documentation commits |
| OWNER_PC | `/home/dev13/ASDEV` on `main`, matches `origin/main` |
| IRAN_PROD platform | `/home/asdev/asdev-platform` ops surface synced; `RELEASE_CANDIDATE.pin` written |

---

## Product commit (frozen)

| Field | Value |
|-------|-------|
| Repo | `alirezasafaei-dev/persiantoolbox` |
| Full SHA | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Short | `fcc7192` |
| Staging release | `20260708T210149Z-fcc7192` |
| Staging health | ready **200**, health **200** |
| Rule | Production **must** use this SHA unless a newer SHA is re-staged |

---

## Reproducible deployment equation

```
ASDEV platform 192d8d5
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
| product commit in meta | matches pin `fcc7192…` |
| ready / health | 200 / 200 |
| prod_current | **no** |
| Live listen | legacy **:3000** (registry staging target remains 3200) |

---

## Deploy method (next gate only)

1. IRAN_PROD platform: `/home/asdev/asdev-platform` (synced)  
2. Product pin `fcc7192…`  
3. Build on host (heap 3072 + swap proven)  
4. `asdev-deploy.sh --site persiantoolbox --environment production --commit fcc7192… --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`  
5. Runtime port **3100**  
6. Health `http://127.0.0.1:3100/api/ready`  

See: `docs/ops/production-execution-plan.md`

---

## Rollback method

- Symlink swap: `asdev-rollback.sh`  
- First production deploy has **no previous release**  
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

---

## Intentionally not executed

- Production deploy / symlink switch  
- nginx reload  
- DNS / SSL  
- migration  
- Staging rebind  

---

## Final strings

```
READY_FOR_PRODUCTION_FREEZE

NEXT_GATE:
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
