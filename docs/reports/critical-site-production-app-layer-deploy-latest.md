# CRITICAL_SITE Production Application-Layer Deploy

**Date:** 2026-07-08T22:16:00Z  
**Approval:** `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`  
**Scope:** **Application layer only** (`127.0.0.1:3100`)  
**Not in scope:** nginx · DNS · SSL · public edge · migration · firewall

---

## Result: **SUCCESS**

| Check | Result |
|-------|--------|
| 1. Release created | **YES** — `20260708T221124Z-fcc7192` |
| 2. current symlink | **YES** → `/srv/asdev/sites/persiantoolbox/releases/20260708T221124Z-fcc7192` |
| 3. Process up | **YES** — pid `72355` alive |
| 4. Health 200 | **YES** — ready **200**, health **200** on `:3100` |
| 5. Rollback command ready | **YES** (see below; first deploy has no previous release) |

---

## Frozen pins used

| Layer | Value |
|-------|-------|
| Product | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Platform engine | main (synced to IRAN_PROD `/home/asdev/asdev-platform`) |
| Staging evidence (unchanged) | `20260708T210149Z-fcc7192` still ready **200** on legacy `:3000` |

---

## Runtime state

| Item | Value |
|------|-------|
| Bind | `127.0.0.1:3100` |
| ready | HTTP 200 |
| health | HTTP 200 |
| staging :3000 | still 200 (untouched) |
| nginx | **not modified** |
| DNS/SSL | **not modified** |
| previous_release | empty (first production release) |

---

## release.meta (production)

```
site=persiantoolbox
environment=production
commit=fcc7192af26a5713e31d4ec078365f9507c8108a
release_id=20260708T221124Z-fcc7192
runtime_port=3100
prod_port=3100
staging_port=3200
```

---

## Rollback (operator)

First production release has **no previous release** for symlink rollback.

**Recovery options:**

1. Redeploy same pin:
```bash
bash scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox \
  --environment production \
  --commit fcc7192af26a5713e31d4ec078365f9507c8108a \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

2. Stop runtime (emergency):
```bash
# pid file: /srv/asdev/sites/persiantoolbox/asdev-runtime.pid
kill $(cat /srv/asdev/sites/persiantoolbox/asdev-runtime.pid)
```

3. After second release exists:
```bash
bash scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment production \
  --commit <audit-sha> \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

---

## Intentionally not executed

- nginx reload / config change  
- DNS change  
- SSL/certbot  
- public hostname launch  
- database migration  
- firewall / fail2ban  
- staging stop/rebind  

---

## Next phase (separate approval)

```
Public edge: nginx → SSL → DNS → Public Launch
```

Suggested future phrase (not granted now):  
`APPROVE_CRITICAL_SITE_PUBLIC_EDGE` (or equivalent owner wording)

---

## Status

```
PRODUCTION_APP_LAYER_LIVE

ready=200 health=200 port=3100
```
