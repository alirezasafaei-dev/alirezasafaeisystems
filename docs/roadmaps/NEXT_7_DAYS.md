# NEXT 7 DAYS — ASDEV Roadmap

**Period:** 2026-07-08 to 2026-07-15  
**Source of Truth:** GitHub  
**Canonical also:** `/NEXT_WEEK_ROADMAP.md`

---

## 1. CRITICAL_SITE production path

- [x] Staging live + health  
- [x] Production app-layer on 3100  
- [ ] Public edge after `APPROVE_CRITICAL_SITE_PUBLIC_EDGE`  
- [ ] External smoke green  
- [ ] Optional staging rebind 3200  

---

## 2. Backup & DR

- [x] DR runbook for CRITICAL_SITE  
- [ ] Onsite backup path under `/srv/asdev/backups`  
- [ ] Restore drill report  

---

## 3. Monitoring

- [x] Foundation scripts + standard  
- [x] App-layer + deploy-status probes  
- [ ] Live timers only with `APPROVE_MONITORING_LIVE_TIMERS`  

---

## 4. Platform standardization

- [x] Universal site-standard template  
- [x] Clean root standard  
- [ ] Second site onboard dry-run using template only  

---

## 5. CI

- [x] Classify multi-workflow fail as infra-class  
- [ ] Confirm green when GHA recovers  
- [ ] Prefer local CI Router for mission merges when infra-red  
