# Clean Root Standard — ASDEV Workspace

**Last Updated:** 2026-07-08  
**Goal:** One mental model for humans and agents. No duplicate project roots.

---

## Canonical roots

| Role | Path | Notes |
|------|------|-------|
| Platform / SoT checkout | `/home/dev13/ASDEV` | Prefer this name in docs and agent prompts |
| Same tree (filesystem) | May resolve to `alirezasafaeisystems` checkout | Must remain a **single** working tree |
| Private secrets (never git) | `/home/dev13/ASDEV_PRIVATE/` | env files, keys metadata |
| Product sources | `/home/dev13/ASDEV/sites/live/<site>` | registry + site-source-map |
| Runtime (IRAN_PROD) | `/srv/asdev/sites/<site>` | releases + shared + current |

**Rule:** Do **not** create a second parallel tree at `/home/dev13/my-project` for active ASDEV work. Historical docs that mention `my-project/sites/live/...` are legacy; migrate references to `/home/dev13/ASDEV`.

---

## Naming

| Concept | Canonical name |
|---------|----------------|
| Mother / platform repo | `alirezasafaeisystems` (GitHub) · workspace `ASDEV` |
| Critical site product | `persiantoolbox` |
| Production host | `IRAN_PROD` |
| Local executor | `OWNER_PC` or `AUTOMATION_HOST` |
| Registry site id | lowercase, no spaces (`persiantoolbox`) |

---

## Directory ownership

| Tree | Owns |
|------|------|
| `deploy/` | registry, deployment standard |
| `scripts/deploy/` | deploy engine |
| `scripts/monitoring/` | probes |
| `scripts/ops/` | validation, remote status, quarantine plans |
| `docs/ops/` | operational runbooks |
| `docs/reports/` | time-stamped mission evidence |
| `docs/automation/` | agent OS, queues, handoff |
| `docs/roadmaps/` | TODAY / 7d / 30d / 90d |
| `ops/nginx/` | edge templates (not auto-applied) |
| `templates/site-standard/` | onboarding skeleton |
| `sites/live/*` | product code |

---

## Anti-patterns

- Second clone used as “production copy” without registry  
- Secrets in `docs/reports`  
- Many micro-PRs for one mission  
- Installing nginx templates without public-edge phrase  
- Treating portfolio-era ports (3000/3001) as CRITICAL_SITE prod ports  

---

## Verification

```bash
# Single ASDEV root
readlink -f /home/dev13/ASDEV

# Registry parse
bash scripts/ops/validate-registry-schema.sh

# No accidental secrets in staged files
bash scripts/scan-secrets.sh || true
```
