# Public Edge Plan — CRITICAL_SITE

**Status:** PREPARED — **not executed**  
**Requires:** `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` (or equivalent explicit owner phrase)  
**Last Updated:** 2026-07-08

---

## Goal

Expose production app layer already running on **`127.0.0.1:3100`** via:

```
Internet → nginx (TLS) → 127.0.0.1:3100
```

Without that phrase: **no nginx reload, no DNS change, no certbot**.

---

## Target topology

```
                    ┌─────────────────────────┐
  HTTPS :443        │  nginx (IRAN_PROD)      │
  ─────────────────►│  server_name:           │
                    │   persiantoolbox.ir     │
                    │   www.persiantoolbox.ir  │
                    └───────────┬─────────────┘
                                │ proxy_pass
                                ▼
                    ┌─────────────────────────┐
                    │ next-server             │
                    │ 127.0.0.1:3100          │
                    │ release: current        │
                    └─────────────────────────┘
```

Optional staging host (later):

```
staging.persiantoolbox.ir → 127.0.0.1:3200
```

Legacy staging today still on **:3000** — rebind before pointing staging vhost to 3200.

---

## Port contract (source of truth)

| Env | Port | Registry field |
|-----|------|----------------|
| production | **3100** | `prod_port` |
| staging | **3200** | `staging_port` |

**Do not** use the old co-hosting defaults (3000/3001) for new CRITICAL_SITE production edge.

Legacy file `ops/nginx/asdev-cohosting.conf` still documents 3000/3001 for portfolio co-hosting era — **do not install as-is** for this cutover.

Canonical template for CRITICAL_SITE production:

- `ops/nginx/critical-site-production-3100.conf.template`

---

## SSL strategy

1. HTTP :80 server block with ACME challenge include only  
2. Issue/renew cert with certbot (webroot or nginx plugin) for:
   - `persiantoolbox.ir`
   - `www.persiantoolbox.ir`
3. HTTPS :443 with:
   - Let's Encrypt fullchain/privkey
   - modern SSL options (`options-ssl-nginx.conf`)
   - HSTS once HTTPS is verified stable (start with max-age short if first public launch)

**Do not** enable HSTS preload on day-one unless owner explicitly accepts lock-in.

---

## Domain routing checklist

| Step | Action | Gate |
|------|--------|------|
| 1 | Confirm app healthy on :3100 | pre-edge |
| 2 | Install nginx template (sites-available) | PUBLIC_EDGE phrase |
| 3 | `nginx -t` | PUBLIC_EDGE |
| 4 | Obtain/renew cert | PUBLIC_EDGE |
| 5 | Enable site + reload nginx | PUBLIC_EDGE |
| 6 | DNS A/AAAA → IRAN_PROD (if not already) | PUBLIC_EDGE + DNS ownership |
| 7 | External smoke: root + ready + health | post |
| 8 | Optional: staging host after rebind 3200 | separate |

---

## Headers & compression (required in template)

- `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto` (proto **https** on TLS vhost)
- `Host` passthrough
- WebSocket upgrade headers (Next may need)
- `gzip` on text/json/js/css/svg
- Security headers (baseline):
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY` (or SAMEORIGIN if product requires embeds)
  - `Referrer-Policy: strict-origin-when-cross-origin`
  - HSTS only after TLS verified

---

## Pre-flight before edge cutover

```bash
# On IRAN_PROD (read-only until approval)
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3100/api/ready
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3100/api/health
ss -ltn | grep 3100

# Config validation only (after files placed; still no reload until ready)
sudo nginx -t
```

---

## Execution sequence (after approval phrase only)

1. Snapshot current nginx configs (backup to non-git path under `/srv/asdev/backups/nginx/…`)  
2. Install template → sites-available  
3. `nginx -t`  
4. Certbot if cert missing  
5. Enable site symlink  
6. `systemctl reload nginx`  
7. External checks (no secrets in logs)  
8. Record `docs/reports/critical-site-public-edge-latest.md`  

Rollback edge:

- Disable new site symlink  
- Restore previous nginx config from backup  
- `nginx -t && systemctl reload nginx`  
- App layer on :3100 remains untouched  

---

## Explicit non-goals (this plan alone)

- Does **not** grant authority to reload nginx  
- Does **not** change DNS  
- Does **not** run migrations  
- Does **not** stop staging  

---

## Approval phrase

```
APPROVE_CRITICAL_SITE_PUBLIC_EDGE
```

Until that phrase is present in the active session, agents **prepare only**.
