# ASDEV Permanent Memory

**Canonical long-lived memory for all agents.**  
**Update after every major phase.**  
**SoT:** GitHub `main`  
**Updated:** 2026-07-09T03:25:00Z

---

## 1. Architecture decisions

| Decision | Detail |
|----------|--------|
| GitHub = only SoT | Host is execution |
| **Autonomous Loop Policy** | `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md` (mandatory) |
| CRITICAL_SITE first ASDEV app-layer | IRAN `:3100`; public live is separate VPS |
| Ports (registry) | prod 3100 / staging 3200 (public uses 3000/3003 blue-green) |
| AUTOMATION_HOST = control plane | Orchestration; not public product runtime |
| Autonomous Productivity Mode | Continue safe work; stop only on real gates |
| Minimal approval gates | edge, migration, prod deploy, staging, live timers, destructive |

---

## 2. Current state

| Component | State |
|-----------|-------|
| Platform main | + loop policy PR (this install) |
| Public CRITICAL_SITE | LIVE green:3003 · release `37ba347` (ubuntu VPS) |
| ASDEV IRAN app-layer | `:3100` separate from public DNS |
| Control plane | scripts + queue + health live — **synced to AUTOMATION_HOST** |
| Loop governance | **INSTALLED** 2026-07-09 |
| Productivity mode | **ENABLED** |
| Agent loop timer | **ACTIVE** — 30m interval, tested OK |
| AUTOMATION_HOST | **OPERATIONAL** — control-plane deployed, linger enabled |

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
