# CRITICAL_SITE Release Candidate Pin

**Last Updated:** 2026-07-08  
**Status:** FROZEN

---

## Product commit pin (verified staging)

| Field | Value |
|-------|-------|
| Product repo | `alirezasafaei-dev/persiantoolbox` |
| Pin SHA | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Short | `fcc7192` |
| Staging release id | `20260708T210149Z-fcc7192` |
| Staging health | ready/health **200** |

**Production must use the same product SHA** unless owner explicitly chooses a newer commit and re-validates staging first.

---

## Platform pin (mother repo)

| Field | Value |
|-------|-------|
| Mother repo | `alirezasafaei-dev/alirezasafaeisystems` |
| Branch | `main` |
| PR | #72 **MERGED** |
| Frozen tip | See `docs/reports/critical-site-release-freeze-latest.md` (current main) |

IRAN_PROD platform checkout: `/home/asdev/asdev-platform` (ops surface synced; no production deploy).

---

## Reproducible pair

```
ASDEV platform (main tip)
+
CRITICAL_SITE product fcc7192
=
production release candidate
```

---

## Execute production (after owner phrase only)

```bash
PRODUCT_COMMIT=fcc7192af26a5713e31d4ec078365f9507c8108a
bash scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox \
  --environment production \
  --commit "$PRODUCT_COMMIT" \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

Runtime port: **3100**
