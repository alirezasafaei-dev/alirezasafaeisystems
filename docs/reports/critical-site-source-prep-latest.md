# CRITICAL_SITE Source Prep — Latest

**Date:** 2026-07-08  
**Task:** ASDEV-STAGING-SOURCE  
**Mode:** automation-script (local only)

---

## Finding

CRITICAL_SITE product code is **not** vendored inside the mother repo.

| Item | Value |
|------|-------|
| Product GitHub | `alirezasafaei-dev/persiantoolbox` (public) |
| Registry repo_path | `sites/live/persiantoolbox` |
| Prior local state | Missing / incomplete quarantine stubs |
| Mother repo role | Deploy registry, scripts, protection, orchestration |

---

## Delivered this cycle

1. `deploy/site-source-map.tsv` — site → git URL map  
2. `scripts/deploy/asdev-prepare-site-source.sh` — dry-run/apply checkout into `sites/live/`  
3. `scripts/deploy/lib/asdev-common.sh` — shared source path resolution  
4. Deploy/preflight use resolver + clear prep hint  
5. `.gitignore` ignores `/sites/live/` (no product tree commits)  
6. `docs/ops/staging-execution-plan.md` — exact commands for post-approval staging  

---

## Local apply result

| Check | Result |
|-------|--------|
| `asdev-prepare-site-source.sh --site persiantoolbox --apply` | OK |
| Local path | `sites/live/persiantoolbox` (gitignored) |
| `package.json` | present |
| Product commit (shallow main) | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Preflight source status | **ready** |
| Deploy dry-run source status | **ready** |
| Committed to mother repo? | **No** (gitignored by design) |

---

## Not done

- Live staging deploy  
- IRAN_PROD path creation  
- Committing product source into mother repo  

---

## Next

1. Confirm local source `ready` via preflight  
2. Owner: `APPROVE_PHASE_2_STAGING_DEPLOY`  
3. Execute staging on host with IRAN_PROD staging base access  
