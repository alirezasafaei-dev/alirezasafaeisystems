# Deployment History & Rollback Maturity

**Last Updated:** 2026-07-08

---

## Goals

- Track releases under `/srv/asdev/sites/<site>/releases/`  
- Always know `current` and `previous_release`  
- Rehearse rollback without production risk  
- Zero-downtime model: symlink cutover + health after activate  

---

## Tools

| Script | Mode |
|--------|------|
| `scripts/deploy/asdev-release-history.sh` | read-only list |
| `scripts/deploy/asdev-rollback-rehearse.sh` | dry-run default |
| `scripts/deploy/asdev-rollback.sh` | real rollback (gated) |
| `scripts/deploy/asdev-deploy.sh` | deploy (gated for prod) |

---

## History on IRAN (CRITICAL_SITE)

```bash
ASDEV_SITE_ROOT=/srv/asdev/sites/persiantoolbox \
  bash /home/asdev/asdev-platform/scripts/deploy/asdev-release-history.sh
```

## Rehearse

```bash
bash scripts/deploy/asdev-rollback-rehearse.sh --site-root /srv/asdev/sites/persiantoolbox
```

First production release: expect `NO_ROLLBACK_TARGET` until second deploy.

---

## Zero-downtime notes

1. Build in new release directory  
2. Healthcheck new release if possible  
3. Atomic `current` symlink swap  
4. Healthcheck after swap  
5. Auto-rollback on health fail (engine behavior)  

App-layer only today; public edge is separate gate.

---

## Artifact tracking

`release.meta` fields: site, environment, commit, release_id, ports, previous_release.
