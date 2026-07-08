# ASDEV Permanent Memory

**Canonical long-lived memory for all agents.**  
**Update after every major phase.**  
**SoT:** GitHub `main`  
**Updated:** 2026-07-08T23:00:00Z

---

## 1. Architecture decisions

| Decision | Detail |
|----------|--------|
| GitHub = only SoT | Host is execution |
| CRITICAL_SITE first prod = app-layer only | Public edge gated separately |
| Ports | prod 3100 / staging 3200 (staging live may still be 3000) |
| AUTOMATION_HOST = control plane | Not public runtime |
| Autonomous Productivity Mode | Continue safe work; stop only on real gates |
| Minimal approval gates | edge, migration, prod deploy, staging deploy, live timers, destructive |

---

## 2. Current state

| Component | State |
|-----------|-------|
| Platform main | evolving via ops PRs |
| CRITICAL_SITE prod | LIVE `20260708T221124Z-fcc7192` pin **fcc7192** on `:3100` |
| CRITICAL_SITE staging | LIVE on legacy `:3000` |
| Public edge | OFF (template ready) |
| Control plane | `control-plane/` + scripts live |
| Meta backup IRAN | daily 03:15 UTC |
| Productivity mode | **ENABLED** |

---

## 3. Completed phases

1. Deploy engine + registry + port isolation  
2. Staging live CRITICAL_SITE  
3. Production app-layer cutover  
4. Stabilization + backup foundation  
5. Control plane transform  
6. Governance + project.yaml standard + OS productivity batch  

---

## 4. Known risks

- First prod has no previous_release  
- Staging port drift (:3000 vs 3200)  
- Meta-only backups  
- Desktop + automation colocation  
- Hermes/OpenClaw outside PM2  
- Shared secrets residual for full product features  

---

## 5. Future roadmap (safe first)

1. Continuous OS maturity (this mode)  
2. Observability foundation → timers when approved  
3. Public edge when phrase  
4. Multi-site onboarding via project.yaml  
5. Second prod release for rollback history (phrase)  

---

## 6. Operating system map

```
GitHub
  └── SoT: code, docs, memory, queue schema
AUTOMATION_HOST
  ├── control-plane/ (queue, agents, health, logs)
  ├── scripts/{deploy,ops,monitoring,control-plane}
  └── docs/{governance,automation,ops,reports}
IRAN_PROD
  └── CRITICAL_SITE runtime + backups
```

---

## 7. Read order for new agents

1. This file (`ASDEV_MEMORY.md`)  
2. `docs/governance/AUTONOMOUS_PRODUCTIVITY_MODE.md`  
3. `docs/governance/APPROVAL_GATES.md`  
4. `docs/automation/AGENT_REGISTRY.md`  
5. `docs/automation/AGENT_MEMORY.md` (session-fresh)  
6. `control-plane/queue/queue.json`  

---

## Changelog

### 2026-07-08 — Productivity mode + OS foundation

- Enabled continuous improvement operating mode  
- Governance pack, project standards, deploy history tools, observability foundation, security audit  

### 2026-07-08 — IRAN history evidence

- Release history: single prod release fcc7192
- Rollback rehearse: NO_ROLLBACK_TARGET confirmed on host

### 2026-07-08 — OS Build Loop v2

- Added docs/memory/*, docs/deployment/UNIVERSAL_DEPLOYMENT_MODEL, docs/observability/*, docs/security/security-baseline, roadmap/, control-plane maturity scripts
- Focus: factory OS not site handwork
