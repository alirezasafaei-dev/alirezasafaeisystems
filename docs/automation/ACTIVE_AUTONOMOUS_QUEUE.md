# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T21:44:19Z
**Status:** Active — RELEASE FROZEN
**Source of Truth:** GitHub main @ `5aff1df`

---

## Frozen pair

| Layer | Pin |
|-------|-----|
| Platform | `5aff1df` (main, PR #72 merged) |
| Product | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Staging evidence | `20260708T210149Z-fcc7192` ready/health 200 |

---

## Queue

### 1. ASDEV-PROD-GATE
- **Title:** CRITICAL_SITE production deploy
- **Approval:** `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`
- **Status:** READY — only remaining gate
- **Status note:** Freeze complete; no production mutation yet

### 2. ASDEV-STAGING-REBIND (optional post-prod)
- **Title:** Rebind staging :3000 → :3200
- **Status:** OPTIONAL

---

## NEXT_GATE

```
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
