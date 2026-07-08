# CRITICAL_SITE Release Candidate Pin

**Last Updated:** 2026-07-08  

---

## Product commit pin (verified staging)

| Field | Value |
|-------|-------|
| Product repo | `alirezasafaei-dev/persiantoolbox` |
| Pin SHA | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Short | `fcc7192` |
| Staging release id | `20260708T210149Z-fcc7192` |
| Staging health | ready/health **200** (re-verified RC audit) |

**Production must use the same product SHA** unless owner explicitly chooses a newer commit and re-validates staging first.

---

## Platform / deploy engine pin

| Field | Value |
|-------|-------|
| Mother repo | `alirezasafaei-dev/alirezasafaeisystems` |
| Release candidate branch | `ops/autonomous-loop-staging-readiness-20260708` |
| PR | #72 |
| GitHub `main` at audit | `eaddee4` (PR **not merged** yet) |

**Frozen:** PR #72 merged. Platform main = `5aff1df`. IRAN_PROD platform checkout synced (no prod deploy).

---

## Artifact strategy

1. Prefer **build on IRAN_PROD** from product pin (proven path; heap 3072 + swap)  
2. Alternative: build on OWNER_PC and transfer slim standalone (network often unreliable)  
3. Release id format: `YYYYMMDDTHHMMSSZ-<7charsha>`  

---

## How to pin at execute time

```bash
PRODUCT_COMMIT=fcc7192af26a5713e31d4ec078365f9507c8108a
# verify still matches staging meta on host if desired
# then:
bash scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox \
  --environment production \
  --commit "$PRODUCT_COMMIT" \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
