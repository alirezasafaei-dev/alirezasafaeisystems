# Public Edge Prep Checklist — CRITICAL_SITE (NO APPLY)

**Status:** PREP ONLY  
**Do not run** nginx reload / certbot / DNS without:

```
APPROVE_CRITICAL_SITE_PUBLIC_EDGE
```

---

## Preconditions (already largely true)

- [x] App layer LIVE on `127.0.0.1:3100` ready/health 200  
- [x] Product pin documented (`fcc7192` family; product main advancing)  
- [x] Nginx template: `ops/nginx/critical-site-production-3100.conf.template`  
- [x] Plan: `docs/ops/public-edge-plan.md`  
- [ ] Owner phrase present in session  
- [ ] Cert paths exist on IRAN for persiantoolbox.ir  
- [ ] DNS A/AAAA confirmed by owner  

## Execution order (after phrase only)

1. Backup current nginx sites-enabled (host path, not git)  
2. Install template → sites-available  
3. `nginx -t`  
4. Certbot if needed  
5. Enable site + `reload`  
6. External smoke: root + ready + health  
7. Report: `docs/reports/critical-site-public-edge-latest.md`  

## Rollback edge

- Restore previous nginx config  
- reload  
- Leave app on :3100 running  

## Product quality gate before public claim of 10/10

Even after edge:

- SEO factory content live  
- No absolute false privacy claims  
- Homepage density controlled  
- Monitoring timers optional next phrase  
