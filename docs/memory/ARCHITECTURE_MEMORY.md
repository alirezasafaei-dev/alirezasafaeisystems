# Architecture Memory

**Stable map — update when topology changes.**

```
GitHub (SoT)
  code · docs · memory · governance · queue schema · PRs
        │
        ▼
AUTOMATION_HOST  (/home/dev13/ASDEV)
  control-plane/     agents queue health logs state
  scripts/deploy     asdev-* engine
  scripts/monitoring probes
  scripts/ops        audit/validate/health
  scripts/control-plane  queue + loops
  docs/              governance memory ops reports
        │ SSH (key local, never git)
        ▼
IRAN_PROD
  /srv/asdev/sites/<site>   releases current shared
  /home/asdev/asdev-platform  synced scripts
  CRITICAL_SITE prod :3100
  CRITICAL_SITE staging :3000 (legacy) / registry 3200
```

## Principles

1. Host executes; GitHub remembers.  
2. Sites run on IRAN, not on AUTOMATION_HOST desktop.  
3. Symlink releases + health after activate.  
4. Distinct prod/staging ports per site.  
5. Agents are registered; tasks are queued.  
