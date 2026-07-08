# Runtime Port Isolation — CRITICAL_SITE

**Last Updated:** 2026-07-08  
**Status:** Target architecture (engine + registry updated; live staging still on legacy 3000 until rebind)

---

## Current state (as of staging LIVE_OK)

| Environment | Path | Runtime port (live today) | Registry target |
|-------------|------|---------------------------|-----------------|
| staging | `/srv/asdev/sites/persiantoolbox-staging` | **3000** (legacy first deploy) | **3200** |
| production | `/srv/asdev/sites/persiantoolbox` | none (untouched) | **3100** |

Problem addressed: both envs previously shared registry port **3000**.

---

## Target state

```
IRAN_PROD
  nginx (optional public edge)
    |
    +-- persiantoolbox.ir        --> 127.0.0.1:3100  (production)
    +-- staging.persiantoolbox.ir --> 127.0.0.1:3200  (staging)

  /srv/asdev/sites/persiantoolbox/
    releases/<id>/          # immutable
    current -> releases/<id>
    shared/

  /srv/asdev/sites/persiantoolbox-staging/
    releases/<id>/
    current -> releases/<id>
```

| Env | Internal port | Public host (planned) |
|-----|---------------|------------------------|
| production | 3100 | persiantoolbox.ir |
| staging | 3200 | staging.persiantoolbox.ir (optional) |

---

## Registry schema

| Column | Meaning |
|--------|---------|
| `prod_port` (col 12) | Production runtime + healthcheck port |
| `staging_port` (col 21) | Staging runtime + healthcheck port |

Validator enforces `prod_port != staging_port`.

---

## Migration / cutover steps (no production yet)

### A) Staging rebind to 3200 (requires staging approval phrase)

1. Confirm registry has staging_port=3200  
2. On IRAN_PROD, stop staging runtime on 3000 (pid file)  
3. Redeploy or restart staging with engine so PORT=3200  
4. Healthcheck `http://127.0.0.1:3200/api/ready`  
5. Leave production untouched  

Phrase: `APPROVE_PHASE_2_STAGING_DEPLOY` (restart/rebind only)

### B) First production deploy on 3100 (requires production phrase)

1. Preflight: port 3100 free  
2. Guard: staging not on 3100  
3. Deploy production → start on 3100  
4. Healthcheck on 3100  
5. Wire nginx only when edge ready (separate approval if reload required)

Phrase: `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`

---

## Rollback plan

| Failure | Action |
|---------|--------|
| Staging rebind health fail | Restart previous staging release on 3200 (or rollback symlink) |
| Production health fail | Automatic symlink rollback to previous prod release; stop failed runtime |
| Port still conflicted | Abort deploy; fix process ownership; no force kill of unrelated services |

---

## Engine guards (implemented)

- Registry isolation: prod_port ≠ staging_port  
- Deploy resolves env-specific port  
- Live deploy refuses if target port listening and not owned by this env pid file  
- Migration change type blocks live deploy without `APPROVE_CRITICAL_SITE_MIGRATION`  
- Healthcheck after activation; failure rolls back symlink  

---

## Nginx (template only — not applied)

```nginx
# production
upstream asdev_pt_prod { server 127.0.0.1:3100; }
server {
  server_name persiantoolbox.ir;
  location / { proxy_pass http://asdev_pt_prod; }
}

# staging (optional public)
upstream asdev_pt_staging { server 127.0.0.1:3200; }
server {
  server_name staging.persiantoolbox.ir;
  location / { proxy_pass http://asdev_pt_staging; }
}
```

Do **not** reload nginx until owner approves edge changes.
